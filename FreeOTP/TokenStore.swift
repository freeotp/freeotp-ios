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
import Security

public class TokenStore : NSObject {
    private final class TokenOrder : NSObject, KeychainStorable {
        static let ACCOUNT = "09E969FC-53C3-4BE2-B653-4802949A26A7"
        static let store = KeychainStore<TokenOrder>()
        let account = ACCOUNT
        let array: NSMutableArray

        override init() {
            array = NSMutableArray()
            super.init()
        }

        @objc init?(coder aDecoder: NSCoder) {
            array = aDecoder.decodeObjectForKey("array") as! NSMutableArray
        }

        @objc private func encodeWithCoder(aCoder: NSCoder) {
            aCoder.encodeObject(array, forKey: "array")
        }
    }

    public var count: Int {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            return ord.array.count
        }

        return 0
    }

    public override init() {
        super.init()

        // Migrate UserDefaults tokens to Keyring tokens
        let def = NSUserDefaults.standardUserDefaults()
        if var keys = def.stringArrayForKey("tokenOrder") {
            var remove = [String]()

            for key in keys.reverse() {
                if let url = def.stringForKey(key) {
                    if let urlc = NSURLComponents(string: url) {
                        if add(urlc) != nil {
                            def.removeObjectForKey(key)
                            remove.append(key)
                        }
                    }
                }
            }

            for key in remove {
                keys.removeAtIndex(keys.indexOf(key)!)
            }

            if keys.count == 0 {
                def.removeObjectForKey("tokenOrder")
            }
        }
    }

    public func add(urlc: NSURLComponents) -> Token? {
        var ord: TokenOrder
        if let a = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            ord = a
        } else {
            ord = TokenOrder()
            if !TokenOrder.store.add(ord) {
                return nil
            }
        }

        if let otp = OTP(urlc: urlc) {
            if let token = Token(otp: otp, urlc: urlc) {
                ord.array.insertObject(otp.account, atIndex: 0)
                if OTP.store.add(otp, locked: token.locked) {
                    if Token.store.add(token) {
                        if TokenOrder.store.save(ord) {
                            return token
                        } else {
                            Token.store.erase(token)
                            OTP.store.erase(otp)
                        }
                    } else {
                        OTP.store.erase(otp)
                    }
                }
            }
        }

        return nil
    }

    public func erase(index index: Int) -> Bool {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            if let account = ord.array.objectAtIndex(index) as? String {
                ord.array.removeObjectAtIndex(index)
                if TokenOrder.store.save(ord) {
                    Token.store.erase(account)
                    OTP.store.erase(account)
                    return true
                }
            }
        }

        return false
    }

    public func erase(token token: Token) -> Bool {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            return erase(index: ord.array.indexOfObject(token.account))
        }

        return false
    }

    public func load(index: Int) -> Token? {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            if let account = ord.array.objectAtIndex(index) as? String {
                return Token.store.load(account)
            }
        }

        return nil
    }

    public func move(from: Int, to: Int) -> Bool {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            if let id = ord.array.objectAtIndex(from) as? String {
                ord.array.removeObjectAtIndex(from)
                ord.array.insertObject(id, atIndex: to)

                return TokenOrder.store.save(ord)
            }
        }

        return false
    }
}
