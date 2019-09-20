//
//  AppDelegate.swift
//  QuickBloxChat
//
//  Created by Bharath on 18/09/19.
//  Copyright © 2019 Bharath. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

struct CredentialsConstant {
//    static let applicationID:UInt = 78492
//    static let authKey = "stDqdfdtzSbAZkN"
//    static let authSecret = "nuV9axeeONBmKw6"
//    static let accountKey = "3YBc2gKmKrzxhX7yogV4"
    
    //voltuswave db
    static let applicationID:UInt = 78139
    static let authKey = "uJtAcqTPw9-EbBG"
    static let authSecret = "6nyKNDFwXfNQ6Gj"
    static let accountKey = "BK9oLu2FmD-Bi4tx5nsr"
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        QBSettings.applicationID = CredentialsConstant.applicationID
        QBSettings.authKey = CredentialsConstant.authKey
        QBSettings.authSecret = CredentialsConstant.authSecret
        QBSettings.accountKey = CredentialsConstant.accountKey
        // enabling carbons for chat
        QBSettings.carbonsEnabled = true
        // Enables Quickblox REST API calls debug console output.
        QBSettings.logLevel = .debug
        // Enables detailed XMPP logging in console output.
        QBSettings.enableXMPPLogging()
        
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        ChatManager.instance.disconnect()

    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        registerForRemoteNotifications()
        ChatManager.instance.connect { (error) in
            if let error = error {
                SVProgressHUD.showError(withStatus: error.localizedDescription)
                return
            }
            
        }

    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        ChatManager.instance.disconnect()

        self.saveContext()
    }

    
    //MARK: - UNUserNotification
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        guard let identifierForVendor = UIDevice.current.identifierForVendor else {
            return
        }
        
        let deviceIdentifier = identifierForVendor.uuidString
        let subscription = QBMSubscription()
        subscription.notificationChannel = .APNS
        subscription.deviceUDID = deviceIdentifier
        subscription.deviceToken = deviceToken
        QBRequest.createSubscription(subscription, successBlock: { response, objects in
        }, errorBlock: { response in
            debugPrint("[AppDelegate] createSubscription error: \(String(describing: response.error))")
        })
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        debugPrint("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "QuickBloxChat")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    
    private func registerForRemoteNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.sound, .alert, .badge], completionHandler: { granted, error in
            if let error = error {
                debugPrint("[AppDelegate] requestAuthorization error: \(error.localizedDescription)")
                return
            }
            center.getNotificationSettings(completionHandler: { settings in
                if settings.authorizationStatus != .authorized {
                    return
                }
                DispatchQueue.main.async(execute: {
                    UIApplication.shared.registerForRemoteNotifications()
                })
            })
        })
    }
    
    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}

//MARK: - UNUserNotificationCenterDelegate
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        if UIApplication.shared.applicationState == .active {
            return
        }
        
        center.removeAllDeliveredNotifications()
        center.removeAllPendingNotificationRequests()
        
        guard let dialogID = userInfo["SA_STR_PUSH_NOTIFICATION_DIALOG_ID".localized] as? String,
            dialogID.isEmpty == false else {
                return
        }
        // calling dispatch async for push notification handling to have priority in main queue
        DispatchQueue.main.async {
            
            if let chatDialog = ChatManager.instance.storage.dialog(withID: dialogID) {
                self.openChat(chatDialog)
            } else {
                ChatManager.instance.loadDialog(withID: dialogID, completion: { (loadedDialog: QBChatDialog?) -> Void in
                    guard let dialog = loadedDialog else {
                        return
                    }
                    self.openChat(dialog)
                })
            }
        }
        completionHandler()
    }
    
    //MARK: Help
    func openChat(_ chatDialog: QBChatDialog) {
        guard let window = window,
            let navigationController = window.rootViewController as? UINavigationController else {
                return
        }
        var controllers = [UIViewController]()
        
        for controller in navigationController.viewControllers {
            controllers.append(controller)
            if controller is DialogsViewController {
                let storyboard = UIStoryboard(name: "Chat", bundle: nil)
                let chatController = storyboard.instantiateViewController(withIdentifier: "ChatViewController") as! ChatViewController
                chatController.dialogID = chatDialog.id
                controllers.append(chatController)
                navigationController.setViewControllers(controllers, animated: true)
                return
            }
        }
    }
}
