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

public class KeychainStore<T: KeychainStorable> {
    private let service: String


    private func query(account: String) -> [String: AnyObject] {
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service
        ]
    }

    private func add(account: String, _ data: NSData, _ locked: Bool = false) -> Bool {
        let date = NSDate()
        var add: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrCreationDate as String: date,
            kSecAttrModificationDate as String: date,
            kSecAttrAccount as String: account,
            kSecAttrService as String: service,
            kSecValueData as String: data,
        ]

        if locked {
            let sac = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .UserPresence,
                nil
            )

            add[kSecAttrAccessControl as String] = sac.takeUnretainedValue()
        } else {
            add[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        }

        return SecItemAdd(add, nil) == errSecSuccess
    }

    public var lockingSupported: Bool {
        let id = NSUUID().UUIDString
        if add(id, NSData(), true) {
            return erase(id)
        }

        return false
    }

    public init() {
        service = NSStringFromClass(T.self)
    }

    public func add(storable: T, locked: Bool = false) -> Bool {
        return add(
            storable.account,
            NSKeyedArchiver.archivedDataWithRootObject(storable),
            locked && lockingSupported
        )
    }

    public func save(storable: T) -> Bool {
        let update: [String: AnyObject] = [
            kSecValueData as String: NSKeyedArchiver.archivedDataWithRootObject(storable),
            kSecAttrModificationDate as String: NSDate(),
        ]

        return SecItemUpdate(query(storable.account), update) == errSecSuccess
    }

    public func load(account: String) -> T? {
        var dict = query(account)
        dict[kSecReturnData as String] = true

        var output: Unmanaged<AnyObject>?
        let status = SecItemCopyMatching(dict, &output)
        if status == errSecSuccess {
            if let o = output {
                let data = o.takeUnretainedValue() as! NSData
                return NSKeyedUnarchiver.unarchiveObjectWithData(data) as? T
            }
        }

        return nil
    }

    public func erase(storable: T) -> Bool {
        return erase(storable.account)
    }

    public func erase(account: String) -> Bool {
        return SecItemDelete(query(account)) == errSecSuccess
    }
}
