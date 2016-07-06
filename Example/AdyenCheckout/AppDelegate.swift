//
//  AppDelegate.swift
//  CheckoutExample
//
//  Created by Taras Kalapun on 11/10/15.
//  Copyright © 2015 Adyen. All rights reserved.
//

import UIKit

let openUrlNotification = "openUrlNotification"
var receivedUrl: NSURL?

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
    }

    func applicationDidEnterBackground(application: UIApplication) {
    }

    func applicationWillEnterForeground(application: UIApplication) {
    }

    func applicationDidBecomeActive(application: UIApplication) {
    }

    func applicationWillTerminate(application: UIApplication) {
    }

    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        receivedUrl = url
        NSNotificationCenter.defaultCenter().postNotificationName(openUrlNotification, object: nil)
        return true
    }
    
}
