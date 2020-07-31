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

class HOTP: XCTestCase {
    func validateOTPs(uri: String, expectedotps: [String]) {
        let urlc = URLComponents(string: uri)
        XCTAssertNotNil(urlc)

        var otp = OTP(urlc: urlc!)
        XCTAssertNotNil(otp)

        let data = NSKeyedArchiver.archivedData(withRootObject: otp!)

        for i in 0..<expectedotps.count {
            XCTAssertEqual(otp!.code(Int64(i)), expectedotps[i])
        }

        otp = NSKeyedUnarchiver.unarchiveObject(with: data) as? OTP
        XCTAssertNotNil(otp)

        for i in 0..<expectedotps.count {
            let code = otp!.code(Int64(i))
            XCTAssertEqual(code, expectedotps[i])
        }
    }

    func test() {
        let tests: [String] = [
            "755224",
            "287082",
            "359152",
            "969429",
            "338314",
            "254676",
            "287922",
            "162583",
            "399871",
            "520489"
        ]
        let uri = "otpauth://hotp/foo?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&algorithm=SHA1&digits=6"

        validateOTPs(uri: uri, expectedotps: tests)
    }

    func testDigits() {
        let tests: [String] = [
            "356072009",
            "318978277",
            "663605382",
            "976886461",
            "607466828",
            "091964552",
            "150788607",
            "729059761",
            "690070028",
            "906336243",
        ]

        let uri7 = "otpauth://hotp/foo?secret=akn3jgzz6d3p4c5r4fokaz2uvxjeltjbdzgyuv4ufscxumc7fjxl5vjh&algorithm=SHA1&digits=7"
        let uri9 = "otpauth://hotp/foo?secret=akn3jgzz6d3p4c5r4fokaz2uvxjeltjbdzgyuv4ufscxumc7fjxl5vjh&algorithm=SHA1&digits=9"

        validateOTPs(uri: uri7, expectedotps: tests.map {
            String($0.dropFirst(2))
        })
        validateOTPs(uri: uri9, expectedotps: tests)
    }
}
