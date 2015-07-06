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

class TokenStore : NSObject {
    private let TOKEN_ORDER = "tokenOrder"
    private var def: NSUserDefaults? = nil

    private func loadKeys(inout array: [String]) {
        if let order = def?.objectForKey(TOKEN_ORDER) {
            for key in order as! [String] {
                array.append(key)
            }
        }
    }

    var count: Int {
        get {
            var keys = Array<String>()
            loadKeys(&keys)
            return keys.count
        }
    }

    override init() {
        super.init()

        def = NSUserDefaults.standardUserDefaults()
    }

    func add(token: Token) -> Bool {
        return add(token, atIndex: 0)
    }

    func add(token: Token, atIndex: Int) -> Bool {
        if def?.stringForKey(token.uid) !== nil {
            return false
        }

        var keys = Array<String>()
        loadKeys(&keys)

        keys.insert(token.uid, atIndex: atIndex)
        def?.setObject(keys, forKey: TOKEN_ORDER)
        def?.setObject(token.description, forKey: token.uid)
        def?.synchronize()
        return true
    }

    func del(token: Token) {
        var keys = Array<String>()
        loadKeys(&keys)

        if let idx = keys.indexOf(token.uid) {
            keys.removeAtIndex(idx)
            def?.setObject(keys, forKey: TOKEN_ORDER)

            def?.removeObjectForKey(token.uid)
            def?.synchronize()
        }
    }

    func get(index: Int) -> Token? {
        var keys = Array<String>()
        loadKeys(&keys)

        if index >= 0 && index < keys.count {
            let key = keys[index]
            if let val = def?.objectForKey(key) {
                if let urlc = NSURLComponents(string: val as! String) {
                    return Token(urlc: urlc, load: true)
                }
            }
        }

        return nil
    }

    func save(token: Token) {
        if let _ = def?.stringForKey(token.uid) {
            def?.setObject(token.description, forKey: token.uid)
            def?.synchronize()
        }
    }

    func move(from: Int, to: Int) {
        var keys = Array<String>()
        loadKeys(&keys)

        if let key: String? = keys[from] {
            keys.removeAtIndex(from)
            keys.insert(key!, atIndex: to)

            def?.setObject(keys, forKey: TOKEN_ORDER)
            def?.synchronize()
        }
    }
}
