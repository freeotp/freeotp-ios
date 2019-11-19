//
//  Icon.swift
//  FreeOTPTests
//
//  Created by Justin Stephenson on 11/19/19.
//  Copyright © 2019 Fedora Project. All rights reserved.
//
import FontAwesome
import Foundation
@testable import FreeOTP
import XCTest

class Icon: XCTestCase {

    func testCustomMapBrandIcon() {
        let issuer = "redhat-2fa"
        let size = CGSize(width: 40, height: 40)

        let tokenIcon = TokenIcon()

        // Test Brands
        let brandIconName = FontAwesome(rawValue: "fa-redhat")!

        let brandExpectedImg = UIImage.fontAwesomeIcon(name: brandIconName, style: .brands, textColor: .white, size: size)
        tokenIcon.saveMapping(issuer: issuer, iconName: "fa-redhat", iconColor: "green")
        let iconInfo = tokenIcon.loadMapping(issuer: issuer)
        XCTAssert(iconInfo!["Name"] == "fa-redhat")
        XCTAssert(iconInfo!["Color"] == "green")

        let mappedIconImg = tokenIcon.getIcon(issuer: issuer, imageSize: size)

        XCTAssert(brandExpectedImg.pngData() == mappedIconImg?.pngData())

        tokenIcon.removeMapping(issuer: issuer)
        let removedInfo = tokenIcon.loadMapping(issuer: issuer)
        XCTAssertNil(removedInfo)
    }

    func testCustomMapSolidIcon() {
        let issuer = "solid-test"
        let size = CGSize(width: 40, height: 40)

        let tokenIcon = TokenIcon()

        // Test Brands
        let brandIconName = FontAwesome(rawValue: "fa-chess")!
        let brandExpectedImg = UIImage.fontAwesomeIcon(name: brandIconName, style: .solid, textColor: .white, size: size)

        tokenIcon.saveMapping(issuer: issuer, iconName: "fa-chess", iconColor: "black")
        let iconInfo = tokenIcon.loadMapping(issuer: issuer)
        XCTAssert(iconInfo!["Name"] == "fa-chess")
        XCTAssert(iconInfo!["Color"] == "black")

        let mappedIconImg = tokenIcon.getIcon(issuer: issuer, imageSize: size)

        XCTAssert(brandExpectedImg.pngData() == mappedIconImg?.pngData())

        tokenIcon.removeMapping(issuer: issuer)
        let removedInfo = tokenIcon.loadMapping(issuer: issuer)
        XCTAssertNil(removedInfo)
    }

    func testBrandIcon() {
        let issuer = "google"
        let size = CGSize(width: 40, height: 40)

        let tokenIcon = TokenIcon()
        let brandIconName = FontAwesome(rawValue: "fa-google")!
        let brandExpectedImg = UIImage.fontAwesomeIcon(name: brandIconName, style: .brands, textColor: .white, size: size)

        let mappedIconImg = tokenIcon.getIcon(issuer: issuer, imageSize: size)

        XCTAssert(brandExpectedImg.pngData() == mappedIconImg?.pngData())
    }

    func testFallbackIcon() {
        let issuer = "unknown-brand"
        let size = CGSize(width: 40, height: 40)

        let tokenIcon = TokenIcon()
        let brandExpectedImg = UIImage(contentsOfFile: Bundle.main.path(forResource: "default", ofType: "png")!)!

        let mappedIconImg = tokenIcon.getIcon(issuer: issuer, imageSize: size)

        XCTAssert(brandExpectedImg.pngData() == mappedIconImg?.pngData())
    }
}
