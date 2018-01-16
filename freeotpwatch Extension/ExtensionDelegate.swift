//
//  ExtensionDelegate.swift
//  FreeOTPWatch Extension
//
//  Created by Jeff Bornemann on 1/15/18.
//  Copyright © 2018 Fedora Project. All rights reserved.
//

import WatchKit
import WatchConnectivity

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate {
    
    var currentToken: String = ""
    var account: String = ""
    
    var to: Date = Date(timeIntervalSinceNow: 5)
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    func applicationDidFinishLaunching() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func updateToken() {
        if WCSession.isSupported() {
            let session = WCSession.default
            if session.isReachable {
                session.sendMessage(["store": 0], replyHandler: { (replyMessage) -> Void in
                    self.currentToken = replyMessage["token"] as! String
                    self.account = replyMessage["account"] as! String
                    self.to = replyMessage["to"] as! Date
                })
            }
            else {
                self.currentToken = ""
                self.account = ""
                self.to = Date(timeIntervalSinceNow: 5)
            }
        }
    }

    func handle(_ backgroundTasks: Set<WKRefreshBackgroundTask>) {
        // Sent when the system needs to launch the application in the background to process tasks. Tasks arrive in a set, so loop through and process each one.
        for task in backgroundTasks {
            // Use a switch statement to check the task type
            switch task {
            case let backgroundTask as WKApplicationRefreshBackgroundTask:
                // Be sure to complete the background task once you’re done.
                backgroundTask.setTaskCompletedWithSnapshot(false)
            case let snapshotTask as WKSnapshotRefreshBackgroundTask:
                // Snapshot tasks have a unique completion call, make sure to set your expiration date
                snapshotTask.setTaskCompleted(restoredDefaultState: true, estimatedSnapshotExpiration: Date.distantFuture, userInfo: nil)
            case let connectivityTask as WKWatchConnectivityRefreshBackgroundTask:
                // Be sure to complete the connectivity task once you’re done.
                connectivityTask.setTaskCompletedWithSnapshot(false)
            case let urlSessionTask as WKURLSessionRefreshBackgroundTask:
                // Be sure to complete the URL session task once you’re done.
                urlSessionTask.setTaskCompletedWithSnapshot(false)
            default:
                // make sure to complete unhandled task types
                task.setTaskCompletedWithSnapshot(false)
            }
        }
    }

}
