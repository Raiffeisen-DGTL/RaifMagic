//
//  NotificationService.swift
//  RaifMagic
//
//  Created by USOV Vasily on 04.06.2024.
//

import Foundation
import UserNotifications

public final class NotificationService: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let center: UNUserNotificationCenter
    
    public override init() {
        center = UNUserNotificationCenter.current()
    }
    
    public func configure() {
        center.delegate = self
    }
    
    public func requestNotificationAuthorization() {
        center.requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
    }
    
    public func sendNotification(title: String, message: String) {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = title
        notificationContent.body = message
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: notificationContent, trigger: nil)
        center.add(request)
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        .banner
    }
}
