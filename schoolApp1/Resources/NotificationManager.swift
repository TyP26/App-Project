//
//  NotificationManager.swift
//  schoolApp1
//
//  Created by Matthias Park 2025 on 6/23/23.
//

import Foundation
import UserNotifications
import UIKit

final class NotificationManager {
    public static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
//    public func getPermission() {
//        notificationCenter.requestAuthorization(options: [.alert, .sound], completionHandler: { (permissionGranted, error) in
//            if !permissionGranted {
//                print("Permission Denied")
//            }
//        })
//    }
}
