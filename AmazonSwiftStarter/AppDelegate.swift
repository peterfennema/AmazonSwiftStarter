//
//  AppDelegate.swift
//  AmazonSwiftStarter
//
//  Created by Peter Fennema on 12/02/16.
//  Copyright © 2016 Peter Fennema. All rights reserved.
//

import UIKit
import IQKeyboardManagerSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window!.backgroundColor = UIColor.whiteColor()
        
        IQKeyboardManager.sharedManager().enable = true
        
        let welcomeViewController = window!.rootViewController as! WelcomeViewController
        welcomeViewController.delegate = self
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


}

// MARK: - WelcomeViewControllerDelegate

extension AppDelegate: WelcomeViewControllerDelegate {
    
    func welcomeViewControllerDidFinish(controller: WelcomeViewController) {
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarVC = storyBoard.instantiateViewControllerWithIdentifier("tabBarController") as! UITabBarController
        self.window!.rootViewController = tabBarVC
        UIView.transitionWithView(window!,
            duration: 0.5,
            options: .TransitionCrossDissolve,
            animations: { () -> Void in
                self.window!.rootViewController = tabBarVC
            },
            completion: nil)
    }
    
}