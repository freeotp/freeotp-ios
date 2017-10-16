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

public protocol KeychainStorable : NSCoding {
    static var store: KeychainStore<Self> { get }
    var account: String { get }
}

open class KeychainStore<T: KeychainStorable> {
    fileprivate let service: String


    fileprivate func query(_ account: String) -> [String: AnyObject] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account as AnyObject,
            kSecAttrService as String: service as AnyObject
        ]
    }

    fileprivate func add(_ account: String, _ data: Data, _ locked: Bool = false) -> Bool {
        let date = Date()
        var add: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrCreationDate as String: date as AnyObject,
            kSecAttrModificationDate as String: date as AnyObject,
            kSecAttrAccount as String: account as AnyObject,
            kSecAttrService as String: service as AnyObject,
            kSecValueData as String: data as AnyObject,
        ]

        if locked {
            let sac = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .userPresence,
                nil
            )

            add[kSecAttrAccessControl as String] = sac
        } else {
            add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }

        return SecItemAdd(add as CFDictionary, nil) == errSecSuccess
    }

    open var lockingSupported: Bool {
        let id = UUID().uuidString
        if add(id, Data(), true) {
            return erase(id)
        }

        return false
    }

    public init() {
        service = NSStringFromClass(T.self)
    }

    @discardableResult open func add(_ storable: T, locked: Bool = false) -> Bool {
        return add(
            storable.account,
            NSKeyedArchiver.archivedData(withRootObject: storable),
            locked && lockingSupported
        )
    }

    @discardableResult open func save(_ storable: T) -> Bool {
        let update: [String: AnyObject] = [
            kSecValueData as String: NSKeyedArchiver.archivedData(withRootObject: storable) as AnyObject,
            kSecAttrModificationDate as String: Date() as AnyObject,
        ]

        return SecItemUpdate(query(storable.account) as CFDictionary, update as CFDictionary) == errSecSuccess
    }

    open func load(_ account: String) -> T? {
        var dict = query(account)
        dict[kSecReturnData as String] = true as AnyObject

        var output: AnyObject?
        let status = SecItemCopyMatching(dict as CFDictionary, &output)
        if status == errSecSuccess {
            if let o = output {
                let data = o as! Data
                return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
            }
        }

        return nil
    }

    @discardableResult open func erase(_ storable: T) -> Bool {
        return erase(storable.account)
    }

    @discardableResult open func erase(_ account: String) -> Bool {
        return SecItemDelete(query(account) as CFDictionary) == errSecSuccess
    }
}
