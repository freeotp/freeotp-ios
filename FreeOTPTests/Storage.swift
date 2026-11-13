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
import FreeOTP
import XCTest

class Storage: XCTestCase {
    func test() {
        let def = UserDefaults.standard
        def.set(["baz:bar"] as [String], forKey: "tokenOrder")
        def.set("otpauth://hotp/foo:bar?secret=JBSWY3DPEHPK3PXP&issuer=baz", forKey: "baz:bar")
        def.synchronize()

        let ts = TokenStore()
        XCTAssertGreaterThan(ts.count, 0)

        let token = ts.load(0)
        XCTAssertNotNil(token)
        XCTAssertEqual(token!.issuer, "foo")
        XCTAssertEqual(token!.label, "bar")
        ts.erase(token: token!)

        XCTAssertNil(def.stringArray(forKey: "tokenOrder"))
        XCTAssertNil(def.string(forKey: "baz:bar"))
    }

    // MARK: - Missing secret detection

    private let uri = "otpauth://totp/MissingSecretTest:user@example.com?secret=JBSWY3DPEHPK3PXP"

    func testHealthyTokenIsNotFlagged() {
        let ts = TokenStore()
        guard let token = ts.add(URLComponents(string: uri)!) else {
            return XCTFail("failed to add token")
        }
        defer { ts.erase(token: token) }

        XCTAssertFalse(OTP.store.isMissing(token.account))
        XCTAssertFalse(token.secretMissing)
        XCTAssertFalse(token.codes.isEmpty)

        let reloaded = Token.store.load(token.account)
        XCTAssertNotNil(reloaded)
        XCTAssertFalse(reloaded!.secretMissing)
    }

    // If the check prompted for authentication, this test would hang.
    func testLockedTokenIsNotFlagged() throws {
        guard Token.store.lockingSupported else {
            throw XCTSkip("Locking unsupported (set a passcode on the simulator/device to run this test)")
        }

        let ts = TokenStore()
        guard let token = ts.add(URLComponents(string: uri + "&lock=true")!) else {
            return XCTFail("failed to add locked token")
        }
        defer { ts.erase(token: token) }

        XCTAssertTrue(token.locked)
        XCTAssertFalse(OTP.store.isMissing(token.account))
        XCTAssertFalse(token.secretMissing)
    }

    func testMissingSecretIsFlagged() {
        let ts = TokenStore()
        guard let token = ts.add(URLComponents(string: uri)!) else {
            return XCTFail("failed to add token")
        }
        defer { ts.erase(token: token) }

        // Metadata present, secret gone: the state after a device transfer.
        XCTAssertTrue(OTP.store.erase(token.account))
        XCTAssertNotNil(Token.store.load(token.account))

        XCTAssertTrue(OTP.store.isMissing(token.account))
        XCTAssertTrue(token.secretMissing)
        XCTAssertTrue(token.codes.isEmpty)
    }

    func testUnknownAccountIsMissing() {
        XCTAssertTrue(OTP.store.isMissing(UUID().uuidString))
    }

    func testRemoveTokenWithMissingSecret() {
        let ts = TokenStore()
        guard let token = ts.add(URLComponents(string: uri)!) else {
            return XCTFail("failed to add token")
        }
        let before = ts.count
        OTP.store.erase(token.account)

        XCTAssertTrue(ts.erase(token: token))
        XCTAssertEqual(ts.count, before - 1)
        XCTAssertNil(Token.store.load(token.account))
    }
}
