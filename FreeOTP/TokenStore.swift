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

open class TokenStore : NSObject {
    @objc fileprivate final class TokenOrder : NSObject, KeychainStorable {
        static let ACCOUNT = "09E969FC-53C3-4BE2-B653-4802949A26A7"
        static let store = KeychainStore<TokenOrder>()
        let account = ACCOUNT
        let array: NSMutableArray

        override init() {
            array = NSMutableArray()
            super.init()
        }

        @objc init?(coder aDecoder: NSCoder) {
            array = aDecoder.decodeObject(forKey: "array") as! NSMutableArray
        }

        @objc fileprivate func encode(with aCoder: NSCoder) {
            aCoder.encode(array, forKey: "array")
        }
    }

    open var count: Int {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            return ord.array.count
        }

        return 0
    }

    public override init() {
        super.init()

        // Migrate UserDefaults tokens to Keyring tokens
        let def = UserDefaults.standard
        if var keys = def.stringArray(forKey: "tokenOrder") {
            var remove = [String]()

            for key in keys.reversed() {
                if let url = def.string(forKey: key) {
                    if let urlc = URLComponents(string: url) {
                        if add(urlc) != nil {
                            def.removeObject(forKey: key)
                            remove.append(key)
                        }
                    }
                }
            }

            for key in remove {
                keys.remove(at: keys.index(of: key)!)
            }

            if keys.count == 0 {
                def.removeObject(forKey: "tokenOrder")
            }
        }
    }

    @discardableResult open func add(_ urlc: URLComponents) -> Token? {
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
                ord.array.insert(otp.account, at: 0)
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

    @discardableResult open func erase(index: Int) -> Bool {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            if let account = ord.array.object(at: index) as? String {
                ord.array.removeObject(at: index)
                if TokenOrder.store.save(ord) {
                    Token.store.erase(account)
                    OTP.store.erase(account)
                    return true
                }
            }
        }

        return false
    }

    @discardableResult open func erase(token: Token) -> Bool {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            return erase(index: ord.array.index(of: token.account))
        }

        return false
    }

    open func load(_ index: Int) -> Token? {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            if let account = ord.array.object(at: index) as? String {
                return Token.store.load(account)
            }
        }

        return nil
    }

    @discardableResult open func move(_ from: Int, to: Int) -> Bool {
        if let ord = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            if let id = ord.array.object(at: from) as? String {
                ord.array.removeObject(at: from)
                ord.array.insert(id, at: to)

                return TokenOrder.store.save(ord)
            }
        }

        return false
    }
}
