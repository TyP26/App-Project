//
//  AppDelegate.swift
//  schoolApp1
//
//  Created by Yash Jagtap on 5/14/23.
//

import UIKit
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn
import UserNotifications
//import Capacitor

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let gcmMessageIDKey = "gcm.Message_ID"
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions:
                     [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FirebaseApp.configure()
        
        // Setting up permissions to send push notifications
        if #available(iOS 10.0, *) {
            // For iOS 10 display notification (sent via APNS)
            UNUserNotificationCenter.current().delegate = self
                    
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
                options: authOptions,
                completionHandler: { _, _ in }
            )
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }
        
        application.registerForRemoteNotifications()
        
        // Messaging Delegate
        Messaging.messaging().delegate = self
        
        return true
    }

//    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        let deviceTokenString = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
//        print("deviceToken:\(deviceTokenString)")
//        NotificationCenter.default.post(name: .capacitorDidRegisterForRemoteNotifications, object: deviceToken)
//    }
//    
//    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        NotificationCenter.default.post(name: .capacitorDidFailToRegisterForRemoteNotifications, object: error)
//    }

//    func application(_ application: UIApplication,
//                didRegisterForRemoteNotificationsWithDeviceToken
//                    deviceToken: Data) {
//        self.shared.sendDeviceTokenToServer(data: deviceToken)
//    }
//
//
//    func application(_ application: UIApplication,
//                didFailToRegisterForRemoteNotificationsWithError
//                    error: Error) {
//       // Try again later.
//    }
    
    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
    -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // ...
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        return [[.banner, .list, .sound]]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        
        // ...
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print full message.
        print(userInfo)
    }
    
    //Silent Notifications
    
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
      -> UIBackgroundFetchResult {
      // If you are receiving a notification message while your app is in the background,
      // this callback will not be fired till the user taps on the notification launching the application.
      // TODO: Handle data of notification

      // With swizzling disabled you must let Messaging know about the message, for Analytics
      // Messaging.messaging().appDidReceiveMessage(userInfo)

      // Print message ID.
      if let messageID = userInfo[gcmMessageIDKey] {
        print("Message ID: \(messageID)")
      }
          
      // Print full message.
      print(userInfo)

      return UIBackgroundFetchResult.newData
    }

    
}

extension AppDelegate: MessagingDelegate {
    
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("Firebase registration token: \(String(describing: fcmToken))")
        
        let dataDict: [String: String] = ["token": fcmToken ?? ""]
        NotificationCenter.default.post(
            name: Notification.Name("FCMToken"),
            object: nil,
            userInfo: dataDict
        )
        // TODO: If necessary send token to application server.
        // Note: This callback is fired at each app startup and whenever a new token is generated.
    }
    
}

//extension AppDelegate: MessagingDelegate {
//    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//      print("Firebase registration token: \(String(describing: fcmToken))")
//
//      let dataDict: [String: String] = ["token": fcmToken ?? ""]
//      NotificationCenter.default.post(
//        name: Notification.Name("FCMToken"),
//        object: nil,
//        userInfo: dataDict
//      )
//      // TODO: If necessary send token to application server.
//      // Note: This callback is fired at each app startup and whenever a new token is generated.
//    }
//
//    func subscribeUser(to topic: String) {
//        // Setting everyone that enters the app to all topic
//        Messaging.messaging().subscribe(toTopic: topic) { error in
//          print("Subscribed to all topic")
//        }
//    }
//
////    func messaging(_ messaging: Messaging, didReceive remoteMessage: MessagingRemoteMessage) {
////        print("Message Data ", remoteMessage.appData)
////    }
//}

//func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//    FirebaseApp.configure()
//
//    UNUserNotificationCenter.current().delegate = self
//    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { success, _ in
//        guard success else {
//            return
//        }
//
//        DispatchQueue.main.async {
//            application.registerForRemoteNotifications()
//        }
//        print("Success in APNS registry")
//    }
//
//    return true
//}
