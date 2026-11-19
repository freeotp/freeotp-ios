//
//  FreeOTPUITests.swift
//  FreeOTPUITests
//
//  Created by Mulili Nzuki on 23/11/2020.
//  Copyright © 2020 Fedora Project. All rights reserved.
//

import XCTest

class FreeOTPUITests: XCTestCase {

    override class func setUp() {
        let app = XCUIApplication()

        app.launch()
        addTestToken(app)
    }

    override class func tearDown() {
        let app = XCUIApplication()

        app.launch()
        removeAllTestTokens(app)

    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    static func addTestToken(_ app: XCUIApplication) {
        let manualAddButton = app.buttons["manualAddButton"].firstMatch
        XCTAssert(manualAddButton.exists)
        manualAddButton.tap()

        let manualAddView = app.otherElements["manualAddView"].firstMatch
        XCTAssert(manualAddView.waitForExistence(timeout: 2.0))

        let issuerField = manualAddView.textFields["issuerField"].firstMatch
        issuerField.tap()
        issuerField.typeText("CopyTest")

        let descriptionField = manualAddView.textFields["descriptionField"].firstMatch
        descriptionField.tap()
        descriptionField.typeText("test@example.com")

        let secretField = manualAddView.textFields["secretField"].firstMatch
        secretField.tap()
        secretField.typeText("mdf3v2s3nzcmwzy5ettbsjq572bpvo5o3wmkfqe7egyktzxufj3hsg7b")

        let nextButton = app.buttons["nextButton"].firstMatch
        nextButton.tap()

        let uriIconView = app.otherElements["uriIconView"].firstMatch
        XCTAssert(uriIconView.waitForExistence(timeout: 2.0))
        uriIconView.cells.firstMatch.tap()
        sleep(1)

        app.buttons["Next"].firstMatch.tap()
        sleep(1)
        app.buttons["Next"].firstMatch.tap()
        sleep(1)
    }


    static func removeAllTestTokens(_ app: XCUIApplication) {
        let collectionView = app.otherElements.collectionViews.firstMatch
        XCTAssert(collectionView.exists)

        let cells = collectionView.cells
        let tokenCount = collectionView.cells.count

        for _ in 1...tokenCount {
            let cell = cells.element(boundBy: 0)
            cell.swipeRight()
            // UIAlertController title sets token.issuer, this reads static text label inside the cell
            let titleLabel = cell.staticTexts.firstMatch

            let actionBtn = app.sheets[titleLabel.label].buttons["Remove token"]
            XCTAssert(actionBtn.waitForExistence(timeout: 5))

            actionBtn.tap()
        }
    }

    func testSearch() throws {
        let app = XCUIApplication()
    
        app.launch()
        
        let collectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(collectionView.exists)
        collectionView.swipeDown()
        
        // check if the search bar exists
        let searchBarElement = app.searchFields.firstMatch
        XCTAssert(searchBarElement.exists)
        searchBarElement.tap()
        
        // check if the filtering works as expected
        app.typeText("test")
        
        XCTAssert(collectionView.cells.count > 0)
        
        // filtering should fail for a random strting
        app.typeText("blah " + String(arc4random()) + " blah")
        XCTAssertFalse(collectionView.cells.count > 0)
    
        let cancelButton = app.buttons["Clear text"].firstMatch
        XCTAssert(cancelButton.exists)
        cancelButton.tap()
    }

    func testManualAdd() throws {
        let app = XCUIApplication()
        
        let typesCount = 2
        let digitsCount = 4
        let algorithmsCount = 6
        let intervalsCount = 6
        let testedIssuerName = "blah123"
    
        app.launch()
        
        let collectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(collectionView.exists)

        //test manual add
        let manualAddButton = app.navigationBars.buttons["manualAddButton"]
        XCTAssert(manualAddButton.waitForExistence(timeout: 5))
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
        
        let minuteButton = algorithmMenu.buttons["1m"].firstMatch
        XCTAssert(minuteButton.exists)
        minuteButton.tap()
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
        
        let iconNextButton = app.buttons["Next"].firstMatch
        XCTAssert(iconNextButton.exists)
        iconNextButton.tap()
        
        let lockNextButton = app.buttons["Next"].firstMatch
        XCTAssert(lockNextButton.exists)
        lockNextButton.tap()

        XCTAssert(collectionView.cells.count == 2)
    }

    func testLongPressCopyMenu() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        let collectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(collectionView.exists)
        let cell = collectionView.cells.firstMatch
        XCTAssert(cell.exists)

        // Assert long press does not work without a visible code.
        cell.press(forDuration: 1.5)
        let prematureCopy = app.buttons["Copy"].firstMatch
        XCTAssertFalse(prematureCopy.waitForExistence(timeout: 1.0))

        // Dimiss any action.
        cell.tap()

        // Assert long press shows copy menu.
        cell.press(forDuration: 1.5)
        let copyButton = app.buttons["Copy"].firstMatch
        XCTAssert(copyButton.waitForExistence(timeout: 2.0))
        copyButton.tap()
    }

    func testLongPressCopyMenu() throws {
        let app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launch()

        let collectionView = app.otherElements.collectionViews.element(boundBy: 0)
        XCTAssert(collectionView.exists)

        // Add a token if none exist.
        if collectionView.cells.count == 0 {
            let manualAddButton = app.buttons["manualAddButton"].firstMatch
            XCTAssert(manualAddButton.exists)
            manualAddButton.tap()

            let manualAddView = app.otherElements["manualAddView"].firstMatch
            XCTAssert(manualAddView.waitForExistence(timeout: 2.0))

            let issuerField = manualAddView.textFields["issuerField"].firstMatch
            issuerField.tap()
            issuerField.typeText("CopyTest")

            let descriptionField = manualAddView.textFields["descriptionField"].firstMatch
            descriptionField.tap()
            descriptionField.typeText("test@example.com")

            let secretField = manualAddView.textFields["secretField"].firstMatch
            secretField.tap()
            secretField.typeText("mdf3v2s3nzcmwzy5ettbsjq572bpvo5o3wmkfqe7egyktzxufj3hsg7b")

            let nextButton = app.buttons["nextButton"].firstMatch
            nextButton.tap()

            let uriIconView = app.otherElements["uriIconView"].firstMatch
            XCTAssert(uriIconView.waitForExistence(timeout: 2.0))
            uriIconView.cells.firstMatch.tap()
            sleep(1)

            app.buttons["Next"].firstMatch.tap()
            sleep(1)
            app.buttons["Next"].firstMatch.tap()
            sleep(1)
        }

        let cell = collectionView.cells.firstMatch
        XCTAssert(cell.exists)

        // Assert long press does not work without a visible code.
        cell.press(forDuration: 1.5)
        let prematureCopy = app.buttons["Copy"].firstMatch
        XCTAssertFalse(prematureCopy.waitForExistence(timeout: 1.0))

        // Dimiss any action.
        cell.tap()
        sleep(1)

        // Assert long press shows copy menu.
        cell.press(forDuration: 1.5)
        let copyButton = app.buttons["Copy"].firstMatch
        XCTAssert(copyButton.waitForExistence(timeout: 2.0))
        copyButton.tap()
    }
}
