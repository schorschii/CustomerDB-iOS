//
//  AppDelegate.swift
//  Copyright © 2018 Georg Sieber. All rights reserved.
//

import UIKit
import CallKit
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, SKPaymentTransactionObserver {

    var window: UIWindow?
    
    var shortcutItemToProcess:UIApplicationShortcutItem?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        initDefaults()
        
        if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
            shortcutItemToProcess = shortcutItem
        }
        
        return true
    }
    
    func initDefaults() {
        let defaults = UserDefaults.standard
        defaults.register(defaults: [
            "unsynced-changes" : false,
            "show-customer-picture" : true,
            "show-phone-field" : true,
            "show-email-field" : true,
            "show-address-field" : true,
            "show-group-field" : true,
            "show-note-field" : true,
            "show-newsletter-field" : true,
            "show-birthday-field" : true,
            "show-files" : true,
            "color-red" : SettingsViewController.DEFAULT_COLOR_R,
            "color-green" : SettingsViewController.DEFAULT_COLOR_G,
            "color-blue" : SettingsViewController.DEFAULT_COLOR_B,
            "currency" : "€",
            "birthday-preview-days": CustomerBirthdayTableViewController.DEFAULT_BIRTHDAY_PREVIEW_DAYS
        ])
        defaults.synchronize()
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        shortcutItemToProcess = shortcutItem
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
        CXCallDirectoryManager.sharedInstance.reloadExtension(withIdentifier: "systems.sieber.customerdb.CustomerDatabaseDirectory", completionHandler: {(error) in
            if let error = error {
                print("CXCallDirectory update error: \(error.localizedDescription)")
            } else {
                print("CXCallDirectory updated")
            }
        })
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        refreshRecipe()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        
        // handle shortcut
        if let shortcutItem = shortcutItemToProcess {
            print("\(shortcutItem.type) triggered")
            
            if let rootvc = window?.rootViewController as? MainSplitViewController {
                    
                    if(shortcutItem.type == "NewCustomerAction") {
                        let detailViewController = rootvc.storyboard?.instantiateViewController(withIdentifier: "CustomerEditNavigationViewController")
                        rootvc.showDetailViewController(detailViewController!, sender: nil)
                    } else if(shortcutItem.type == "NewAppointmentAction") {
                        let detailViewController = rootvc.storyboard?.instantiateViewController(withIdentifier: "AppointmentEditNavigationViewController")
                        rootvc.showDetailViewController(detailViewController!, sender: nil)
                    } else if(shortcutItem.type == "NewVoucherAction") {
                        let detailViewController = rootvc.storyboard?.instantiateViewController(withIdentifier: "VoucherEditNavigationViewController")
                        rootvc.showDetailViewController(detailViewController!, sender: nil)
                    }
                    
            }
            
            shortcutItemToProcess = nil
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func refreshRecipe() {
        // update cloud access license receipt after auto-renewal
        SKPaymentQueue.default().add(self)
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    }
    func request(_ request: SKRequest, didFailWithError error: Error) {
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for tx in transactions {
            switch (tx.transactionState) {
                case .purchased, .restored:
                    queue.finishTransaction(tx)
                    break
                case .failed, .purchasing, .deferred: break
                @unknown default: break
            }
        }
    }
    
}
