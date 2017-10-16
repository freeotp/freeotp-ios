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

import FreeOTP
import XCTest

class URI: XCTestCase {
    func valid(_ string: String, load: Bool = false) -> Token? {
        if let urlc = URLComponents(string: string) {
            if let otp = OTP(urlc: urlc) {
                if let token = Token(otp: otp, urlc: urlc, load: load) {
                    return token
                }
            }
        }

        return nil
    }

    func test() {
        // Test cases that are suppossed to fail
        XCTAssertNil(valid("xxxxxxx://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP"))
        XCTAssertNil(valid("otpauth://xxxx/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&counter=-1"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&period=-1"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&period=1"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&digits=-1"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&digits=1"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&digits=5"))
        XCTAssertNil(valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&digits=10"))

        // Test the basic test case
        let urlc = URLComponents(string: "otpauth://hotp/Example:alice@google.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2&image=http%3A%2F%2Ffoo%2Fbar")
        XCTAssertNotNil(urlc)
        var token = TokenStore().add(urlc!)
        XCTAssertNotNil(token)
        XCTAssertEqual(token!.issuer, "Example")
        XCTAssertEqual(token!.label, "alice@google.com")
        XCTAssertEqual(token!.image!, "http://foo/bar")
        XCTAssertEqual(token!.codes[0].value, "755224")

        // Make sure save and restore work
        token = TokenStore().load(0)
        XCTAssertNotNil(token)
        XCTAssertEqual(token!.codes[0].value, "287082")
        XCTAssert(TokenStore().erase(token: token!))

        // Make sure that the file://*/FreeOTP.app/default.png URLs aren't loaded
        token = valid("otpauth://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP&image=file%3A%2F%2Ffoo%2Fbar%2FFreeOTP.app%2Fdefault.png&imageOrig=file%3A%2F%2Ffoo%2Fbar%2FFreeOTP.app%2Fdefault.png&issuerOrig=foo&nameOrig=bar", load: true)
        XCTAssertNotNil(token)
        XCTAssertEqual(token!.issuer, "Example")
        XCTAssertEqual(token!.label, "alice@google.com")
        XCTAssertNil(token!.image)
    }
}
