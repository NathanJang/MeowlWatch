//
//  AppDelegate.swift
//  MeowlWatch
//
//  Created by Jonathan Chan on 2017-03-17.
//  Copyright © 2018 Jonathan Chan. All rights reserved.
//

import UIKit
import MeowlWatchData

#if !MEOWLWATCH_FULL
    import GoogleMobileAds
#endif

import Siren

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let tintColor = UIColor(red: 128/255, green: 0, blue: 1, alpha: 1)

    let warningColor = UIColor(red: 1, green: 0xbb/255, blue: 0, alpha: 1)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        MeowlWatchData.loadFromDefaults()

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = MenuTableViewController(style: .grouped)
//        reloadRootVC()
        window?.makeKeyAndVisible()

        #if !MEOWLWATCH_FULL
            if MeowlWatchData.shouldDisplayAds {
                GADMobileAds.configure(withApplicationID: MeowlWatchData.adMobAppID)
            }
        #else
            MeowlWatchData.widgetIsPurchased = true
        #endif

        Siren.shared.wail()

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        MeowlWatchData.persistToUserDefaults()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.

        let navigationController = window!.rootViewController as! NavigationController
        if let meowlWatchViewController = navigationController.topViewController as? MeowlWatchTableViewController {

            #if !MEOWLWATCH_FULL
                if MeowlWatchData.shouldDisplayAds {
                    navigationController.conditionallyDisplayModals()
                }
            #endif

            meowlWatchViewController.refreshIfNeeded(animated: false)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        (window!.rootViewController as! NavigationController).popToRootViewControllerOrSettingsAnimatedIfNeeded()
        return true
    }

    func reloadRootVC() {
        let bundleToLoad: Bundle = currentLocalizedBundle.path(forResource: "Main", ofType: "storyboardc") != nil ? currentLocalizedBundle : Bundle(path: Bundle.main.path(forResource: "Base", ofType: "lproj")!)!
        let storyboard = UIStoryboard(name: "Main", bundle: bundleToLoad)
        let rootViewController = storyboard.instantiateInitialViewController()
        window?.rootViewController = rootViewController
    }

}

