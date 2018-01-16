//
//  InterfaceController.swift
//  FreeOTPWatch Extension
//
//  Created by Jeff Bornemann on 1/15/18.
//  Copyright © 2018 Fedora Project. All rights reserved.
//

import WatchKit
import WatchConnectivity
import Foundation


class InterfaceController: WKInterfaceController {
    
    @IBOutlet var token: WKInterfaceLabel!
    @IBOutlet var account: WKInterfaceLabel!

    var timer: Timer?

    let delegate: ExtensionDelegate = WKExtension.shared().delegate as! ExtensionDelegate
    
    @IBAction func update() {
        delegate.updateToken()
        updateText()
        setTimer()
    }
    
    func updateText() {
        if !delegate.currentToken.isEmpty {
            account.setText(delegate.account)
            token.setText(delegate.currentToken)
        }
        else {
            account.setText("")
            token.setText("Connecting..")
        }
    }
    
    func setTimer() {
        unsetTimer()
        let timeToRun = delegate.to.timeIntervalSinceNow > 0 ? delegate.to.timeIntervalSinceNow : TimeInterval(1)
        timer = Timer.scheduledTimer(timeInterval: timeToRun, target: self, selector: #selector(update), userInfo: nil, repeats: false)
    }
    
    func unsetTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    override func willActivate() {
        super.willActivate()
        // This method is called when watch view controller is about to be visible to user
        update()
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        unsetTimer()
    }
    
}

