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

        XCTAssert(icon.getfaIconName(for: "redhat") == "fa-redhat")
        XCTAssert(icon.getfaIconName(for: "github") == "fa-github")
        XCTAssert(icon.getfaIconName(for: "amazon") == "fa-amazon")
        XCTAssert(icon.getfaIconName(for: "google") == "fa-google")
        XCTAssert(icon.getfaIconName(for: "SkyPe") == "fa-skype")
        XCTAssert(icon.getfaIconName(for: "Red Hat") == "fa-redhat")

        XCTAssertNil(icon.getfaIconName(for: "fa-github"))

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
        let iconChoice = "fa-slack"
        let color = "#74DFDF"
        let label = URI.getLabel(from: urlc!)
        icon.saveMapping(issuer: label!.issuer, iconName: iconChoice, iconColor: color)

        let custIcon = icon.getCustomIcon(issuer: label!.issuer)
        XCTAssertNotNil(custIcon)
        XCTAssert(iconChoice == custIcon!.name)

        // Test an exact match issuer -> icon lookup
        let faIconGithub = icon.getfaIconName(for: "github")
        let faIconSlack = icon.getfaIconName(for: "slack")
        let faIconMicrosoft = icon.getfaIconName(for: "microsoft")
        XCTAssertNotNil(icon.getFontAwesomeIcon(faName: faIconGithub!, faType: .brands))
        XCTAssertNotNil(icon.getFontAwesomeIcon(faName: faIconSlack!, faType: .brands))
        XCTAssertNotNil(icon.getFontAwesomeIcon(faName: faIconMicrosoft!, faType: .brands))

        // Test solids
        XCTAssertNotNil(icon.getFontAwesomeIcon(faName: "fa-snowman", faType: .solid))
        XCTAssertNotNil(icon.getFontAwesomeIcon(faName: "fa-archive", faType: .solid))
        XCTAssertNil(icon.getFontAwesomeIcon(faName: "redhat", faType: .solid))
    }
}
