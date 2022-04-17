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

    func testManualAdd() throws {
        let app = XCUIApplication()
        
        let typesCount = 2
        let digitsCount = 4
        let algorithmsCount = 6
        let intervalsCount = 6
        let testedIssuerName = "blah123"
        var testedIssuerTokensCount = 0
    
        app.launch()
        
        //search for the number of old tokens with the issuer name under test
        let searchButton = app.navigationBars.buttons["navbarSearchItem"]
        XCTAssert(searchButton.exists)
        searchButton.tap()
        
        let searchBarElement = app.descendants(matching: .any).matching(identifier: "search-bar").firstMatch
        XCTAssert(searchBarElement.exists)
        searchBarElement.tap()
        
        app.typeText(testedIssuerName)
        let collectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(collectionView.exists)
        testedIssuerTokensCount = collectionView.cells.count
        
        let cancelButton = app.buttons["Cancel"].firstMatch
        XCTAssert(cancelButton.exists)
        cancelButton.tap()

        //test manual add
        let manualAddButton = app.buttons["manualAddButton"].firstMatch
        XCTAssert(manualAddButton.exists)
        manualAddButton.tap()
        
        let manualAddView = app.otherElements["manualAddView"].firstMatch
        XCTAssert(manualAddView.exists)
        
        let nextButton = app.buttons["nextButton"].firstMatch
        XCTAssert(nextButton.exists)
        
        let issuerField = manualAddView.textFields["issuerField"].firstMatch
        XCTAssert(issuerField.exists)
        
        let descriptionField = manualAddView.textFields["descriptionField"].firstMatch
        XCTAssert(descriptionField.exists)
        
        let secretField = manualAddView.textFields["secretField"].firstMatch
        XCTAssert(secretField.exists)
        
        let typeSegmentedControl = manualAddView.segmentedControls["typeControl"].firstMatch
        XCTAssert(typeSegmentedControl.exists)
        XCTAssert(typeSegmentedControl.buttons.count == typesCount)
        
        let digitsSegmentedControl = manualAddView.segmentedControls["digitsControl"].firstMatch
        XCTAssert(digitsSegmentedControl.exists)
        XCTAssert(digitsSegmentedControl.buttons.count == digitsCount)
        
        let algorithmButton = manualAddView.buttons["algorithmControl"].firstMatch
        XCTAssert(algorithmButton.exists)
        
        let intervalButton = manualAddView.buttons["intervalControl"].firstMatch
        XCTAssert(intervalButton.exists)
        
        //check empty fields alert
        nextButton.tap()
        let emptyAlert = app.alerts.firstMatch
        XCTAssert(emptyAlert.staticTexts["Some fields are empty!"].exists)
        
        emptyAlert.buttons.firstMatch.tap()
        
        //check wrong secret alert
        descriptionField.tap()
        descriptionField.typeText(UUID().uuidString)
        issuerField.tap()
        issuerField.typeText(testedIssuerName)
        secretField.tap()
        secretField.typeText("d")
        
        nextButton.tap()
        let secretAlert = app.alerts.firstMatch
        XCTAssert(secretAlert.staticTexts["Token is invalid!"].exists)
        
        secretAlert.buttons.firstMatch.tap()
        guard let text = secretField.value as? String else {
            XCTFail("secret field text failing")
            return
        }
        XCTAssert(text == "")
        
        //check algorithm menu
        algorithmButton.tap()
        let algorithmMenu = app.alerts.firstMatch
        XCTAssert(algorithmMenu.exists)
        XCTAssert(algorithmMenu.buttons.count == algorithmsCount + 1)
        
        let sha1Button = algorithmMenu.buttons["SHA1"].firstMatch
        XCTAssert(sha1Button.exists)
        sha1Button.tap()
        XCTAssert(algorithmButton.label == "SHA1")
        
        //check interval menu
        intervalButton.tap()
        let intervalMenu = app.alerts.firstMatch
        XCTAssert(intervalMenu.exists)
        XCTAssert(intervalMenu.buttons.count == intervalsCount + 1)
        
        let intervalButton15 = algorithmMenu.buttons["1m"].firstMatch
        XCTAssert(intervalButton15.exists)
        intervalButton15.tap()
        XCTAssert(intervalButton.label == "1m")
        
        //check with correct input
        secretField.tap()
        secretField.typeText("mdf3v2s3nzcmwzy5ettbsjq572bpvo5o3wmkfqe7egyktzxufj3hsg7b")
        
        nextButton.tap()
        
        let uriIconView = app.otherElements["uriIconView"].firstMatch
        XCTAssert(uriIconView.waitForExistence(timeout: 1.0))
        let cell = uriIconView.cells.firstMatch
        XCTAssert(cell.exists)
        cell.tap()
        sleep(1)
        
        let iconNextButton = app.buttons["Next"].firstMatch
        XCTAssert(iconNextButton.exists)
        iconNextButton.tap()
        sleep(1)
        
        let lockNextButton = app.buttons["Next"].firstMatch
        XCTAssert(lockNextButton.exists)
        lockNextButton.tap()
        sleep(1)
        
        //detecting an increase in the number of cells with the issuer name under test
        let secSearchButton = app.navigationBars.buttons["navbarSearchItem"]
        XCTAssert(secSearchButton.exists)
        secSearchButton.tap()
        
        let secSearchBarElement = app.descendants(matching: .any).matching(identifier: "search-bar").firstMatch
        XCTAssert(secSearchBarElement.exists)
        secSearchBarElement.tap()
        
        app.typeText(testedIssuerName)
        let secCollectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(secCollectionView.exists)
        XCTAssert(secCollectionView.cells.count == testedIssuerTokensCount + 1)
        
    }
    
}
