//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2015  Nathaniel McCallum, Red Hat
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Base32
import Foundation

class Token : NSObject {
    private var size: Int32 = CC_SHA1_DIGEST_LENGTH
    private var algo: Int = kCCHmacAlgSHA1
    private var counter: UInt64 = 0
    private var digits: UInt = 6
    private var period: UInt64 = 30

    private var issuerOrig: String = ""
    private var labelOrig: String = ""
    private var imageOrig: String?

    private var secret: NSData?
    private var issuerInt: String?

    enum Type {
        case HOTP
        case TOTP
    }

    class Code {
        private(set) var value: String
        private(set) var from: NSDate
        private(set) var to: NSDate
        private init(_ value: String, _ from: NSDate, _ to: NSDate) {
            self.value = value
            self.from = from
            self.to = to
        }
    }

    private(set) var type: Type = .HOTP

    var issuer: String! {
        didSet {
            if issuer == nil { issuer = issuerOrig }
        }
    }

    var label: String! {
        didSet {
            if label == nil { label = labelOrig }
        }
    }

    var image: String? {
        didSet {
            if image == nil { image = imageOrig }
        }
    }

    override var description: String {
        get {
            return uri.string!
        }
    }

    var uri: NSURLComponents {
        get {
            let urlc = NSURLComponents()
            urlc.scheme = "otpauth"

            switch type {
            case .HOTP:
                urlc.host = "hotp"
            case .TOTP:
                urlc.host = "totp"
            }

            var alg: String = ""
            switch algo {
            case kCCHmacAlgMD5:
                alg = "MD5"
            case kCCHmacAlgSHA1:
                alg = "SHA1"
            case kCCHmacAlgSHA224:
                alg = "SHA224"
            case kCCHmacAlgSHA256:
                alg = "SHA256"
            case kCCHmacAlgSHA384:
                alg = "SHA384"
            case kCCHmacAlgSHA512:
                alg = "SHA512"
            default:
                break
            }

            urlc.path = "/"
            if issuer != "" {
                urlc.path! += issuer
                urlc.path! += ":"
            }
            urlc.path! += label

            urlc.queryItems = [
                NSURLQueryItem(name: "algorithm", value: alg),
                NSURLQueryItem(name: "digits", value: String(digits)),
                NSURLQueryItem(name: "secret", value: secret!.base32EncodedString),
                NSURLQueryItem(name: "period", value: String(period)),
                NSURLQueryItem(name: "issuerorig", value: issuerOrig),
                NSURLQueryItem(name: "nameorig", value: labelOrig),
            ]

            if issuerInt != nil {
                urlc.queryItems!.append(NSURLQueryItem(name: "issuer", value: issuerInt))
            }

            if self.image != nil {
                urlc.queryItems!.append(NSURLQueryItem(name: "image", value: self.image))
            }

            if self.imageOrig != nil {
                urlc.queryItems!.append(NSURLQueryItem(name: "imageorig", value: self.imageOrig))
            }

            if type == .HOTP {
                urlc.queryItems!.append(NSURLQueryItem(name: "counter", value: String(counter)))
            }

            return urlc;
        }
    }

    var uid: String {
        get {
            return String(format: "%@:%@", issuerInt == nil ? issuerOrig : issuerInt!, labelOrig)
        }
    }

    var codes: [Code] {
        get {
            var now = NSDate()

            switch type {
            case .HOTP:
                return [Code(getHOTP(counter++), now, now.dateByAddingTimeInterval(NSTimeInterval(period)))]

            case .TOTP:
                func totp(now: NSDate) -> Code {
                    let c = UInt64(now.timeIntervalSince1970) / period
                    let i = NSDate(timeIntervalSince1970: NSTimeInterval(c * period))
                    return Code(getHOTP(c), i, i.dateByAddingTimeInterval(NSTimeInterval(period)))
                }

                return [totp(now), totp(now.dateByAddingTimeInterval(NSTimeInterval(period)))]
            }
        }
    }

    init?(urlc: NSURLComponents, load: Bool = false) {
        super.init()

        if urlc.scheme != "otpauth" || urlc.host == nil {
            return nil
        }

        // Get type
        switch urlc.host!.lowercaseString {
        case "totp":
            type = .TOTP

        case "hotp":
            type = .HOTP

        default:
            return nil
        }

        // Normalize path
        var path = urlc.path == nil ? "" : urlc.path!
        while path.hasPrefix("/") {
            path = path.substringFromIndex(advance(path.startIndex, 1))
        }
        if path == "" {
            return nil
        }

        // Get issuer and label
        let comps = path.componentsSeparatedByString(":")
        switch comps.count {
        case 1:
            label = comps[0]

        case 2:
            issuer = comps[0]
            label = comps[1]

        default:
            return nil
        }

        let query = urlc.queryItems
        if (query == nil) { return nil }
        for item: NSURLQueryItem in query! {
            if item.value == nil { continue }

            switch item.name {
            case "secret":
                secret = item.value!.base32DecodedData

            case "algorithm":
                switch item.value!.lowercaseString {
                case "md5":
                    algo = kCCHmacAlgMD5
                    size = CC_MD5_DIGEST_LENGTH
                case "sha1":
                    algo = kCCHmacAlgSHA1
                    size = CC_SHA1_DIGEST_LENGTH
                case "sha224":
                    algo = kCCHmacAlgSHA224
                    size = CC_SHA224_DIGEST_LENGTH
                case "sha256":
                    algo = kCCHmacAlgSHA256
                    size = CC_SHA256_DIGEST_LENGTH
                case "sha384":
                    algo = kCCHmacAlgSHA384
                    size = CC_SHA384_DIGEST_LENGTH
                case "sha512":
                    algo = kCCHmacAlgSHA512
                    size = CC_SHA512_DIGEST_LENGTH
                default:
                    return nil
                }

            case "digits":
                switch item.value! {
                case "6":
                    digits = 6
                case "8":
                    digits = 8
                default:
                    return nil
                }

            case "period":
                if let tmp: UInt64? = UInt64(item.value!) {
                    period = tmp!
                }

            case "counter":
                if let tmp: UInt64? = UInt64(item.value!) {
                    counter = tmp!
                }

            case "image":
                image = item.value!

            case "issuer":
                issuerInt = item.value!

            case "issuerorig":
                if load { issuerOrig = item.value! }

            case "nameorig":
                if load { labelOrig = item.value! }

            case "imageorig":
                if load { imageOrig = item.value! }

            default:
                continue
            }
        }

        if (secret == nil) {
            return nil
        }

        if load {
            // This works around a bug where we stored a URL to the default image,
            // but this changed with the app id.
            if self.image != nil && self.image!.hasPrefix("file:") && self.image!.hasSuffix("/FreeOTP.app/default.png") {
                self.image = nil
            }
            if self.imageOrig != nil && self.imageOrig!.hasPrefix("file:") && self.imageOrig!.hasSuffix("/FreeOTP.app/default.png") {
                self.imageOrig = nil
            }
        } else {
            issuerOrig = issuer
            labelOrig = label
            imageOrig = image
        }
    }

    private func getHOTP(var counter: UInt64) -> String {
        // Network byte order
        counter = counter.bigEndian

        // Create digits divisor
        var div: UInt32 = 1
        for _ in 1...digits {
            div *= 10
        }

        // Create the HMAC
        var digest = Array<UInt8>(count: Int(size), repeatedValue: 0)
        CCHmac(UInt32(algo), secret!.bytes, secret!.length, &counter, sizeof(UInt64), &digest);

        // Unparse UInt32
        let off: Int = Int(digest[size - 1]) & 0x0f;
        let byt = Array<UInt8>(digest[off..<off+sizeof(UInt32)])
        let dec = (UnsafePointer<UInt32>(byt).memory.bigEndian & 0x7fffffff) % div

        return String(format: String(format: "%%0%hhulu", digits), dec)
    }
}
