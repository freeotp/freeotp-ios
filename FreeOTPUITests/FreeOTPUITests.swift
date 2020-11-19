//
//  FreeOTPUITests.swift
//  FreeOTPUITests
//
//  Created by Mulili Nzuki on 23/11/2020.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import XCTest

class FreeOTPUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testSearch() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
    
        app.launch()
        
        // check the search icon is set
        let leftNavBarSearchButton = app.navigationBars.buttons["navbarSearchItem"]
        XCTAssert(leftNavBarSearchButton.exists)
        leftNavBarSearchButton.tap()
        
        // check if the search bar exists
        let searchBarElement = app.descendants(matching: .any).matching(identifier: "search-bar").firstMatch
        XCTAssert(searchBarElement.exists)
        searchBarElement.tap()
        
        // check if the filtering works as expected
        app.typeText("test")
        let collectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(collectionView.exists)
        XCTAssert(collectionView.cells.count > 0)
        
        // filtering should fail for a random strting
        app.typeText("blah " + String(arc4random()) + " blah")
        XCTAssertFalse(collectionView.cells.count > 0)
    
    }

    
}
