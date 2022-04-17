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
    @objc(_TokenOrder) fileprivate final class TokenOrder : NSObject, KeychainStorable {
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
        guard let ord = TokenOrder.store.load(TokenOrder.ACCOUNT)
        else { return 0 }
        return ord.array.count
    }

    public override init() {
        super.init()

        // Migrate UserDefaults tokens to Keyring tokens
        let def = UserDefaults.standard
        if var keys = def.stringArray(forKey: "tokenOrder") {
            var remove = [String]()
            for key in keys.reversed() {
                if let url = def.string(forKey: key),
                   let urlc = URLComponents(string: url),
                   add(urlc) != nil {
                    def.removeObject(forKey: key)
                    remove.append(key)
                }
            }

            for key in remove {
                keys.remove(at: keys.firstIndex(of: key)!)
            }

            if keys.count == 0 {
                def.removeObject(forKey: "tokenOrder")
            }
        }
    }
    
    func getAllTokens() -> [Token] {
        let orderedTokens = TokenOrder.store.load(TokenOrder.ACCOUNT)
        return orderedTokens != nil ? orderedTokens!.array.map { Token.store.load($0 as! String)! } : []
     }

    @discardableResult open func add(_ urlc: URLComponents) -> Token? {
        var ord: TokenOrder
        if let a = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            ord = a
        } else {
            ord = TokenOrder()
            guard TokenOrder.store.add(ord) else { return nil }
        }

        guard let otp = OTP(urlc: urlc),
              let token = Token(otp: otp, urlc: urlc)
        else { return nil }
        
        ord.array.insert(otp.account, at: 0)
        
        guard OTP.store.add(otp, locked: token.locked) else { return nil }
        guard Token.store.add(token) else {
            OTP.store.erase(otp)
            return nil
        }
        
        guard TokenOrder.store.save(ord) else {
            Token.store.erase(token)
            OTP.store.erase(otp)
            return nil
        }
        return token
    }
    
    @discardableResult
    func add(manualData: ManualInputTokenData) -> Token? {
        var ord: TokenOrder
        if let a = TokenOrder.store.load(TokenOrder.ACCOUNT) {
            ord = a
        } else {
            ord = TokenOrder()
            guard TokenOrder.store.add(ord) else { return nil }
        }

        guard let otp = OTP(manualData: manualData),
              let token = Token(otp: otp, manualData: manualData)
        else { return nil }
        
        ord.array.insert(otp.account, at: 0)
        
        guard OTP.store.add(otp, locked: token.locked) else { return nil }
        guard Token.store.add(token) else {
            OTP.store.erase(otp)
            return nil
        }
        
        guard TokenOrder.store.save(ord) else {
            Token.store.erase(token)
            OTP.store.erase(otp)
            return nil
        }
        return token
    }
    
    @discardableResult open func erase(index: Int) -> Bool {
        guard let ord = TokenOrder.store.load(TokenOrder.ACCOUNT),
              let account = ord.array.object(at: index) as? String
        else { return false }
        
        ord .array.removeObject(at: index)
        guard TokenOrder.store.save(ord)else { return false }
        
        Token.store.erase(account)
        OTP.store.erase(account)
        return true
    }
    
    @discardableResult open func erase(token: Token) -> Bool {
        guard let ord = TokenOrder.store.load(TokenOrder.ACCOUNT)
        else { return false }
        return erase(index: ord.array.index(of: token.account))
    }
    
    open func load(_ index: Int) -> Token? {
        guard let ord = TokenOrder.store.load(TokenOrder.ACCOUNT),
              let account = ord.array.object(at: index) as? String
        else { return nil }
        return Token.store.load(account)
    }
    
    @discardableResult open func move(_ from: Int, to: Int) -> Bool {
        guard let ord = TokenOrder.store.load(TokenOrder.ACCOUNT),
              let id = ord.array.object(at: from) as? String
        else { return false }
        ord.array.removeObject(at: from)
        ord.array.insert(id, at: to)
        return TokenOrder.store.save(ord)
    }
}
