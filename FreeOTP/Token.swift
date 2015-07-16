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

import Foundation

public final class Token : NSObject, KeychainStorable {
    public static let store = KeychainStore<Token>()
    public let account: String

    public enum Kind: Int {
        case HOTP = 0
        case TOTP = 1
    }

    public class Code {
        private(set) public var value: String
        private(set) public var from: NSDate
        private(set) public var to: NSDate

        private init(_ value: String, _ from: NSDate, _ period: Int64) {
            self.value = value
            self.from = from
            self.to = from.dateByAddingTimeInterval(NSTimeInterval(period))
        }
    }

    private var issuerOrig: String = ""
    private var labelOrig: String = ""
    private var imageOrig: String?
    private var counter: Int64 = 0
    private var period: Int64 = 30

    private (set) public var kind: Kind = .HOTP

    public var locked: Bool = false {
        didSet {
            if let otp = OTP.store.load(account) {
                if OTP.store.erase(otp) {
                    if OTP.store.add(otp, locked: locked) {
                        return
                    }
                }
            }

            locked = !locked
        }
    }

    public var codes: [Code] {
        if let otp = OTP.store.load(account) {
            let now = NSDate()

            switch kind {
            case .HOTP:
                let code = Code(otp.code(counter++), now, period)
                if Token.store.save(self) {
                    return [code]
                }

            case .TOTP:
                func totp(otp: OTP, now: NSDate) -> Code {
                    let c = Int64(now.timeIntervalSince1970) / period
                    let i = NSDate(timeIntervalSince1970: NSTimeInterval(c * period))
                    return Code(otp.code(c), i, period)
                }

                let next = now.dateByAddingTimeInterval(NSTimeInterval(period))
                return [totp(otp, now: now), totp(otp, now: next)]
            }
        }

        return []
    }

    public var issuer: String! = nil {
        didSet {
            if issuer == nil { issuer = issuerOrig }
        }
    }

    public var label: String! = nil {
        didSet {
            if label == nil { label = labelOrig }
        }
    }

    public var image: String? = nil {
        didSet {
            if image == nil { image = imageOrig }
        }
    }

    public init?(otp: OTP, urlc: NSURLComponents, load: Bool = false) {
        self.account = otp.account
        super.init()

        if urlc.scheme != "otpauth" || urlc.host == nil {
            return nil
        }

        // Get kind
        switch urlc.host!.lowercaseString {
        case "totp":
            kind = .TOTP

        case "hotp":
            kind = .HOTP

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
        issuer = comps[0]
        label = comps.count > 1 ? comps[1] : ""

        let query = urlc.queryItems
        if (query == nil) { return nil }
        for item: NSURLQueryItem in query! {
            if item.value == nil { continue }

            switch item.name.lowercaseString {
            case "period":
                if let tmp = Int64(item.value!) {
                    if tmp < 5 {
                        return nil
                    }

                    period = tmp
                }

            case "counter":
                if let tmp = Int64(item.value!) {
                    if tmp < 0 {
                        return nil
                    }

                    counter = tmp
                }

            case "lock":
                switch item.value!.lowercaseString {
                case "": fallthrough
                case "0": fallthrough
                case "off": fallthrough
                case "false":
                    locked = false

                default:
                    locked = Token.store.lockingSupported
                }

            case "image":
                image = item.value!
                if !load { image = item.value! }

            case "issuerorig":
                if !load { issuerOrig = item.value! }

            case "nameorig":
                if !load { labelOrig = item.value! }

            case "imageorig":
                if !load { imageOrig = item.value! }

            default:
                continue
            }
        }

        if load {
            // This works around a bug where we stored a URL to the default image,
            // but this changed with the app id.
            if image != nil && image!.hasPrefix("file:") && image!.hasSuffix("/FreeOTP.app/default.png") {
                image = nil
            }
            if imageOrig != nil && imageOrig!.hasPrefix("file:") && imageOrig!.hasSuffix("/FreeOTP.app/default.png") {
                imageOrig = nil
            }
        } else {
            imageOrig = image
            issuerOrig = issuer
            labelOrig = label
        }
    }

    @objc required public init?(coder aDecoder: NSCoder) {
        locked = aDecoder.decodeBoolForKey("locked")
        account = aDecoder.decodeObjectForKey("account") as! String
        counter = aDecoder.decodeInt64ForKey("counter")
        image = aDecoder.decodeObjectForKey("image") as? String
        imageOrig = aDecoder.decodeObjectForKey("imageOrig") as? String
        issuer = aDecoder.decodeObjectForKey("issuer") as! String
        issuerOrig = aDecoder.decodeObjectForKey("issuerOrig") as! String
        kind = Kind(rawValue: aDecoder.decodeIntegerForKey("kind"))!
        label = aDecoder.decodeObjectForKey("label") as! String
        labelOrig = aDecoder.decodeObjectForKey("labelOrig") as! String
        period = aDecoder.decodeInt64ForKey("period")

        super.init()
    }

    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeBool(locked, forKey: "locked")
        aCoder.encodeObject(account, forKey: "account")
        aCoder.encodeInt64(counter, forKey: "counter")
        aCoder.encodeObject(image, forKey: "image")
        aCoder.encodeObject(imageOrig, forKey: "imageOrig")
        aCoder.encodeObject(issuer, forKey: "issuer")
        aCoder.encodeObject(issuerOrig, forKey: "issuerOrig")
        aCoder.encodeInteger(kind.rawValue, forKey: "kind")
        aCoder.encodeObject(label, forKey: "label")
        aCoder.encodeObject(labelOrig, forKey: "labelOrig")
        aCoder.encodeInt64(period, forKey: "period")
    }
}
