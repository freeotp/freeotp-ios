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

    func testUnicodeChars() {
        let example_one = "otpauth://hotp/Example:firstname.lastname%40example.com%20(foobar)%20-%20TESTING?secret=qfwpwaf2d5korpye6x5ldftjcitb2dvk5ozbvvizslayv2ezdt3mgf5o&algorithm=SHA256&digits=6&period=30&counter=0"

        let urlc = URLComponents(string: example_one)
        XCTAssertNotNil(urlc)

        let token = TokenStore().add(urlc!)
        XCTAssertNotNil(token)
        XCTAssertEqual(token!.issuer, "Example")
        XCTAssertEqual(token!.label, "firstname.lastname@example.com (foobar) - TESTING")

        let exampleChinese = "otpauth://hotp/%E7%81%AB%E5%B0%B8%E6%9C%A8%E7%81%AB1%E5%8D%81%E5%AF%A5%E6%97%A5%E7%83%A4:%E7%81%AB%E6%97%A5%E8%82%96%E3%80%80%E4%BD%A0%EF%BC%9B%E7%81%AB?secret=qfwpwaf2d5korpye6x5ldftjcitb2dvk5ozbvvizslayv2ezdt3mgf5o&algorithm=SHA256&digits=6&period=30&counter=0"

        let urlcChinese = URLComponents(string: exampleChinese)
          XCTAssertNotNil(urlcChinese)

        let tokenChinese = TokenStore().add(urlcChinese!)
        XCTAssertEqual(tokenChinese!.issuer, "火尸木火1十寥日烤")
        XCTAssertEqual(tokenChinese!.label, "火日肖　你；火")

        let exampleUnicode = "otpauth://hotp/Robert%E2%80%99s%E2%80%9D!!%40%23%24%25%5E:slkdjfkj%22%22%C3%A9!%22'%C3%A8(%C3%A0%C3%A9%C3%A9!%C3%A9?secret=qfwpwaf2d5korpye6x5ldftjcitb2dvk5ozbvvizslayv2ezdt3mgf5o&algorithm=SHA256&digits=6&period=30&counter=0"

        let urlcUnicode = URLComponents(string: exampleUnicode)
          XCTAssertNotNil(urlcUnicode)

        let tokenUnicode = TokenStore().add(urlcUnicode!)
        XCTAssertEqual(tokenUnicode!.issuer, "Robert’s”!!@#$%^")
        XCTAssertEqual(tokenUnicode!.label, "slkdjfkj\"\"é!\"'è(àéé!é")
    }

    func testUnsetParams() {
        let params = URIParameters()
        let urlc = URLComponents(string: "otpauth://hotp/Example:alice@google.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2&image=http%3A%2F%2Ffoo%2Fbar&lock=true")
        let urlcUnset = URLComponents(string: "otpauth://hotp/Example?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2")
        XCTAssertNotNil(urlcUnset)
        XCTAssertTrue(params.accountUnset(urlcUnset!))

        XCTAssertFalse(params.paramUnset(urlc!, "image", ""))
        XCTAssertTrue(params.paramUnset(urlcUnset!, "image", ""))

        XCTAssertFalse(params.paramUnset(urlc!, "lock", ""))
        XCTAssertTrue(params.paramUnset(urlcUnset!, "lock", ""))
    }

    func testGetParams() {
        let params = URIParameters()
        let urlc = URLComponents(string: "otpauth://hotp/Example:alice@google.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2&image=http%3A%2F%2Ffoo%2Fbar")
        let urlcAcctOnly = URLComponents(string: "otpauth://hotp/Example?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&image=http%3A%2F%2Ffoo%2Fbar")

        let label = params.getLabel(from: urlc!)
        XCTAssert(label != nil)
        XCTAssert(label!.issuer == "Example")
        XCTAssert(label!.account == "alice@google.com")

        let label2 = params.getLabel(from: urlcAcctOnly!)
        XCTAssert(label2 != nil)
        XCTAssert(label2!.account == "Example")
        XCTAssert(label2!.issuer == "")
    }

    func testValidateURI() {
        let params = URIParameters()

        XCTAssertFalse(params.validateURI(uri: URLComponents(string: "xxxxxxx://hotp/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP")!))
        XCTAssertFalse(params.validateURI(uri: URLComponents(string: "otpauth://xxxx/Example:alice@google.com?secret=JBSWY3DPEHPK3PXP")!))
        XCTAssertFalse(params.validateURI(uri: URLComponents(string: "otpauth://hotp/Example:alice@google.com")!))
        XCTAssertFalse(params.validateURI(uri: URLComponents(string: "otpauth://hotp/?secret=by6p223gcdxtmxakeaqapld6um3k6x2gos5lcgvlaznjxcgw5cudwr5y&algorithm=SHA256&digits=6&period=30&counter=0")!))

        XCTAssert(params.validateURI(uri: URLComponents(string: "otpauth://hotp/Example:alice@google.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2&image=http%3A%2F%2Ffoo%2Fbar")!))
    }
}
