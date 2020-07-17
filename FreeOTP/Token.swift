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
import MobileCoreServices

public final class Token : NSObject, KeychainStorable, Codable, NSItemProviderReading, NSItemProviderWriting {
    public static let store = KeychainStore<Token>()
    public let account: String

    public enum Kind: Int, Codable {
        case hotp = 0
        case totp = 1
    }

    enum CodingKeys: String, CodingKey {
        case locked
        case account
        case counter
        case image
        case imageOrig
        case issuer
        case issuerOrig
        case color
        case icon
        case kind
        case label
        case labelOrig
        case period
    }

    open class Code {
        fileprivate(set) open var value: String
        fileprivate(set) open var from: Date
        fileprivate(set) open var to: Date

        fileprivate init(_ value: String, _ from: Date, _ period: Int64) {
            self.value = value
            self.from = from
            self.to = from.addingTimeInterval(TimeInterval(period))
        }
    }

    fileprivate var issuerOrig: String = ""
    fileprivate var labelOrig: String = ""
    fileprivate var imageOrig: String?
    fileprivate var counter: Int64 = 0
    fileprivate var period: Int64 = 30

    fileprivate (set) public var kind: Kind = .hotp

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
            let now = Date()

            switch kind {
            case .hotp:
                let code = Code(otp.code(counter), now, period)
                counter += 1
                if Token.store.save(self) {
                    return [code]
                }

            case .totp:
                func totp(_ otp: OTP, now: Date) -> Code {
                    let c = Int64(now.timeIntervalSince1970) / period
                    let i = Date(timeIntervalSince1970: TimeInterval(c * period))
                    return Code(otp.code(c), i, period)
                }

                let next = now.addingTimeInterval(TimeInterval(period))
                return [totp(otp, now: now), totp(otp, now: next)]
            }
        }

        return []
    }

    @objc public var issuer: String! = nil {
        didSet {
            if issuer == nil { issuer = issuerOrig }
        }
    }

    @objc public var label: String! = nil {
        didSet {
            if label == nil { label = labelOrig }
        }
    }

    @objc public var image: String? = nil {
        didSet {
            if image == nil { image = imageOrig }
        }
    }

    var color: String?

    var icon: String?

    public init?(otp: OTP, urlc: URLComponents, load: Bool = false) {
        self.account = otp.account
        super.init()

        if urlc.scheme != "otpauth" || urlc.host == nil {
            return nil
        }

        // Get kind
        switch urlc.host!.lowercased() {
        case "totp":
            kind = .totp

        case "hotp":
            kind = .hotp

        default:
            return nil
        }

        // Normalize path
        var path = urlc.path
        while path.hasPrefix("/") {
            path = String(path[path.index(path.startIndex, offsetBy: 1)...])
        }

        if path == "" {
            return nil
        }

        // Get issuer and label
        let comps = path.components(separatedBy: ":")
        issuer = comps[0]
        label = comps.count > 1 ? comps[1] : ""

        let query = urlc.queryItems
        if (query == nil) { return nil }
        for item: URLQueryItem in query! {
            if item.value == nil { continue }

            switch item.name.lowercased() {
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
                switch item.value!.lowercased() {
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

            case "color":
                color = item.value!

            case "icon":
                icon = item.value!

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

    // Conform to NSItemProvider Protocols
    public static var writableTypeIdentifiersForItemProvider: [String] {
         return [(kUTTypeData) as String]
     }

     public func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {

         let progress = Progress(totalUnitCount: 100)

         do {
             let encoder = JSONEncoder()
             encoder.outputFormatting = .prettyPrinted
             let data = try encoder.encode(self)
            _ = String(data: data, encoding: String.Encoding.utf8)
             progress.completedUnitCount = 100
             completionHandler(data, nil)
         } catch {
             completionHandler(nil, error)
         }

         return progress
     }

     public static var readableTypeIdentifiersForItemProvider: [String] {
         return [(kUTTypeData) as String]
     }

     public static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Token {
         let decoder = JSONDecoder()
         do {
             let tokenjson = try decoder.decode(Token.self, from: data)
             return tokenjson
         } catch {
             fatalError("Error decoding token object")
         }
     }

    @objc required public init?(coder aDecoder: NSCoder) {
        locked = aDecoder.decodeBool(forKey: "locked")
        account = aDecoder.decodeObject(forKey: "account") as! String
        counter = aDecoder.decodeInt64(forKey: "counter")
        image = aDecoder.decodeObject(forKey: "image") as? String
        imageOrig = aDecoder.decodeObject(forKey: "imageOrig") as? String
        issuer = aDecoder.decodeObject(forKey: "issuer") as? String
        issuerOrig = aDecoder.decodeObject(forKey: "issuerOrig") as! String
        color = aDecoder.decodeObject(forKey: "color") as? String
        icon = aDecoder.decodeObject(forKey: "icon") as? String
        kind = Kind(rawValue: aDecoder.decodeInteger(forKey: "kind"))!
        label = aDecoder.decodeObject(forKey: "label") as? String
        labelOrig = aDecoder.decodeObject(forKey: "labelOrig") as! String
        period = aDecoder.decodeInt64(forKey: "period")

        super.init()
    }

    @objc public func encode(with aCoder: NSCoder) {
        aCoder.encode(locked, forKey: "locked")
        aCoder.encode(account, forKey: "account")
        aCoder.encode(counter, forKey: "counter")
        aCoder.encode(image, forKey: "image")
        aCoder.encode(imageOrig, forKey: "imageOrig")
        aCoder.encode(issuer, forKey: "issuer")
        aCoder.encode(issuerOrig, forKey: "issuerOrig")
        aCoder.encode(color, forKey: "color")
        aCoder.encode(icon, forKey: "icon")
        aCoder.encode(kind.rawValue, forKey: "kind")
        aCoder.encode(label, forKey: "label")
        aCoder.encode(labelOrig, forKey: "labelOrig")
        aCoder.encode(period, forKey: "period")
    }
}
