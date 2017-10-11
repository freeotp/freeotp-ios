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

        let urlc = URLComponents(string: "otpauth://hotp/foo?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&algorithm=SHA1&digits=6")
        XCTAssertNotNil(urlc)

        var otp = OTP(urlc: urlc!)
        XCTAssertNotNil(otp)

        let data = NSKeyedArchiver.archivedData(withRootObject: otp!)

        for i in 0..<tests.count {
            XCTAssertEqual(otp!.code(Int64(i)), tests[i])
        }

        otp = NSKeyedUnarchiver.unarchiveObject(with: data) as? OTP
        XCTAssertNotNil(otp)

        for i in 0..<tests.count {
            let code = otp!.code(Int64(i))
            XCTAssertEqual(code, tests[i])
        }
    }
}
