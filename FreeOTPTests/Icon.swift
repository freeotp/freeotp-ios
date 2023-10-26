//
//  Icon.swift
//  FreeOTPTests
//
//  Created by Justin Stephenson on 5/13/20.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import FreeOTP
import XCTest

class Icon: XCTestCase {

    func testMapping() {
        let URI = URIParameters()
        let icon = TokenIcon()
        let urlc = URLComponents(string: "otpauth://hotp/Example:alice@google.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2&image=http%3A%2F%2Ffoo%2Fbar")
        let iconChoice = "fa-amazon"
        let color = "#74DFDF"
        let expected = ["Name": iconChoice, "Color": color]
        if let label = URI.getLabel(from: urlc!) {
            icon.saveMapping(issuer: label.issuer, iconName: iconChoice, iconColor: color)
            if let iconMapping = icon.loadMapping(issuer: label.issuer) {
                XCTAssert(iconMapping == expected)
                return
            }
        }

        XCTFail()
    }

    func testBrand() {
        let icon = TokenIcon()

        XCTAssert(icon.getBrandColorHex("redhat") == "#FF0000")
        XCTAssert(icon.getBrandColorHex("gitlab") == "#292961")
        XCTAssert(icon.getBrandColorHex("steam") == "#242424")

        let redhatColor = UIColor(hexString: "#FF0000")
        let gitlabColor = UIColor(hexString: "#292961")
        let steamColor = UIColor(hexString: "242424")

        XCTAssert(icon.getBrandColor("redhat") == redhatColor)
        XCTAssert(icon.getBrandColor("gitlab") == gitlabColor)
        XCTAssert(icon.getBrandColor("fa-steam") == steamColor)

        XCTAssertNil(icon.getBrandColor(("test")))

        XCTAssert(icon.getBackgroundColor(name: "redhat") == redhatColor)
        XCTAssert(icon.getBackgroundColor(name: "gitlab") == gitlabColor)
    }

    func testFontAwesome() {
        // Test an issuer -> icon mapping saved from the URIIcon wizard
        // Issuer: Example -> Icon: Slack
        let URI = URIParameters()
        let icon = TokenIcon()
        let urlc = URLComponents(string: "otpauth://hotp/Example:alice@google.com?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Example2&image=http%3A%2F%2Ffoo%2Fbar")
        let iconChoice = "slack"
        let color = "#74DFDF"
        let label = URI.getLabel(from: urlc!)
        icon.saveMapping(issuer: label!.issuer, iconName: iconChoice, iconColor: color)

        let custIcon = icon.getCustomIcon(issuer: label!.issuer)
        XCTAssertNotNil(custIcon)
        XCTAssert(iconChoice == custIcon!.name)

        // Test an exact match issuer -> icon lookup
        XCTAssertNotNil(UIImage.fontAwesomeIcon(faName: "github", faType: .brands))
        XCTAssertNotNil(UIImage.fontAwesomeIcon(faName: "slack", faType: .brands))
        XCTAssertNotNil(UIImage.fontAwesomeIcon(faName: "microsoft", faType: .brands))

        // Test solids
        XCTAssertNotNil(UIImage.fontAwesomeIcon(faName: "fa-snowman", faType: .solid))
        XCTAssertNotNil(UIImage.fontAwesomeIcon(faName: "fa-archive", faType: .solid))
        XCTAssertNotNil(UIImage.fontAwesomeIcon(faName: "redhat", faType: .solid))
    }
}
