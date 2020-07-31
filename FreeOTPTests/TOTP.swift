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
import Foundation
import XCTest

class TOTP: XCTestCase {
    struct TestData {
        let time: Int64
        let code: String
    }

    func validateOTPs(uri: String, otpdata: [TestData]) {
        let urlc = URLComponents(string: uri)
        XCTAssertNotNil(urlc)

        var otp = OTP(urlc: urlc!)
        XCTAssertNotNil(otp)

        let data = NSKeyedArchiver.archivedData(withRootObject: otp!)

        for d in otpdata {
            XCTAssertEqual(otp!.code(d.time / Int64(30)), d.code)
        }

        otp = NSKeyedUnarchiver.unarchiveObject(with: data) as? OTP
        XCTAssertNotNil(otp)

        for d in otpdata {
            XCTAssertEqual(otp!.code(d.time / Int64(30)), d.code)
        }
    }

    func testSHA1() {
        let tests: [TestData] = [
            TestData(time: 59,          code: "94287082"),
            TestData(time: 1111111109,  code: "07081804"),
            TestData(time: 1111111111,  code: "14050471"),
            TestData(time: 1234567890,  code: "89005924"),
            TestData(time: 2000000000,  code: "69279037"),
            TestData(time: 20000000000, code: "65353130"),
        ]

        let uri = "otpauth://totp/foo?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&algorithm=SHA1&digits=8"
        validateOTPs(uri: uri, otpdata: tests)
    }

    func testSHA256() {
        let tests: [TestData] = [
            TestData(time: 59,          code: "46119246"),
            TestData(time: 1111111109,  code: "68084774"),
            TestData(time: 1111111111,  code: "67062674"),
            TestData(time: 1234567890,  code: "91819424"),
            TestData(time: 2000000000,  code: "90698825"),
            TestData(time: 20000000000, code: "77737706"),
        ]

        let uri = "otpauth://totp/foo?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZA====&algorithm=SHA256&digits=8"
        validateOTPs(uri: uri, otpdata: tests)
    }

    func testSHA512() {
        let tests: [TestData] = [
            TestData(time: 59,          code: "90693936"),
            TestData(time: 1111111109,  code: "25091201"),
            TestData(time: 1111111111,  code: "99943326"),
            TestData(time: 1234567890,  code: "93441116"),
            TestData(time: 2000000000,  code: "38618901"),
            TestData(time: 20000000000, code: "47863826"),
        ]

        let uri = "otpauth://totp/foo?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNA=&algorithm=SHA512&digits=8"
        validateOTPs(uri: uri, otpdata: tests)
    }

    func testDigits() {
        let tests: [TestData] = [
            TestData(time: 59,          code: "318978277"),
            TestData(time: 1111111109,  code: "985507210"),
            TestData(time: 1111111111,  code: "846109060"),
            TestData(time: 1234567890,  code: "462647324"),
            TestData(time: 2000000000,  code: "910524948"),
            TestData(time: 20000000000, code: "137696517"),
        ]

        let uri9 = "otpauth://totp/foo?secret=akn3jgzz6d3p4c5r4fokaz2uvxjeltjbdzgyuv4ufscxumc7fjxl5vjh&algorithm=SHA1&digits=9"
        let uri7 = "otpauth://totp/foo?secret=akn3jgzz6d3p4c5r4fokaz2uvxjeltjbdzgyuv4ufscxumc7fjxl5vjh&algorithm=SHA1&digits=7"

        validateOTPs(uri: uri9, otpdata: tests)
        let tests7 = tests.map {
            (value: TestData) -> TestData in
            return TestData(time: value.time, code: String(value.code.dropFirst(2)))
        }

        validateOTPs(uri: uri7, otpdata: tests7)
    }
}
