//
//  WatchSessionDelegate.swift
//  FreeOTP
//
//  Created by Jeff Bornemann on 1/16/18.
//  Copyright © 2018 Fedora Project. All rights reserved.
//

import Foundation
import WatchConnectivity

class WatchSessionDelegate : NSObject, WCSessionDelegate {

    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession,
                 didReceiveMessage message: [String : Any],
                 replyHandler: @escaping ([String : Any]) -> Void) {
        let store: Int = message["store"] as! Int
        let nextToken: Token? = TokenStore().load(store)
        if nextToken != nil {
            replyHandler(["token": nextToken?.codes[0].value as Any,
                          "account": nextToken?.account as Any,
                          "to": nextToken?.codes[0].to as Any])
        }
        else {
            replyHandler(["token": "",
                          "account": "",
                          "to": Date(timeIntervalSinceNow: 5)])
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}
