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

public final class OTP : NSObject, KeychainStorable {
    public static let store = KeychainStore<OTP>()
    public let account: String

    private var algo: Int = Int(kCCHmacAlgSHA1)
    private var size: Int = Int(CC_SHA1_DIGEST_LENGTH)
    private var secret: NSData = NSData()
    private var digits: Int = 6

    public init?(urlc: NSURLComponents) {
        account = NSUUID().UUIDString
        super.init()

        if let query = urlc.queryItems {
            for item: NSURLQueryItem in query {
                if item.value == nil { continue }

                switch item.name.lowercaseString {
                case "secret":
                    if let s = item.value!.base32DecodedData {
                        secret = s
                    } else {
                        return nil
                    }

                case "algorithm":
                    switch item.value!.lowercaseString {
                    case "md5":
                        algo = Int(kCCHmacAlgMD5)
                        size = Int(CC_MD5_DIGEST_LENGTH)
                    case "sha1":
                        algo = Int(kCCHmacAlgSHA1)
                        size = Int(CC_SHA1_DIGEST_LENGTH)
                    case "sha224":
                        algo = Int(kCCHmacAlgSHA224)
                        size = Int(CC_SHA224_DIGEST_LENGTH)
                    case "sha256":
                        algo = Int(kCCHmacAlgSHA256)
                        size = Int(CC_SHA256_DIGEST_LENGTH)
                    case "sha384":
                        algo = Int(kCCHmacAlgSHA384)
                        size = Int(CC_SHA384_DIGEST_LENGTH)
                    case "sha512":
                        algo = Int(kCCHmacAlgSHA512)
                        size = Int(CC_SHA512_DIGEST_LENGTH)
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

                default:
                    continue
                }
            }
        }

        if secret.length == 0 {
            return nil
        }
    }

    @objc required public init?(coder aDecoder: NSCoder) {
        account = aDecoder.decodeObjectForKey("account") as! String
        secret = aDecoder.decodeObjectOfClass(NSData.self, forKey: "secret") as! NSData
        algo = aDecoder.decodeIntegerForKey("algo")
        size = aDecoder.decodeIntegerForKey("size")
        digits = aDecoder.decodeIntegerForKey("digits")
        super.init()
    }

    @objc public func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(account, forKey: "account")
        aCoder.encodeObject(secret, forKey: "secret")
        aCoder.encodeInteger(algo, forKey: "algo")
        aCoder.encodeInteger(size, forKey: "size")
        aCoder.encodeInteger(digits, forKey: "digits")
    }

    public func code(counter: Int64) -> String {
        // Network byte order
        var cnt = counter.bigEndian

        // Do the HMAC
        var buf = [UInt8](count: size, repeatedValue: 0)
        CCHmac(UInt32(algo), secret.bytes, secret.length, &cnt, sizeofValue(cnt), &buf)

        // Unparse UInt32
        let off = Int(buf[buf.count - 1]) & 0x0f;
        let arr = UnsafePointer<UInt32>(UnsafePointer<UInt8>(buf).advancedBy(off))
        let msk = arr[0].bigEndian & 0x7fffffff

        // Create digits divisor
        var div: UInt32 = 1
        for _ in 0..<digits { div *= 10 }

        return String(format: String(format: "%%0%hhulu", digits), msk % div)
    }
}
