//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by Yureka on 29/05/20.
//  Copyright © 2020 Yureka. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = localized(value: bestAttemptContent.title)
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
    
    private var appLanguage: String {
        if let userDefault = UserDefaults(suiteName: "group.localize") {
            if let currentLang = userDefault.string(forKey: LanguageManagerKeys.selectedLanguage) {
                return currentLang
            }
            return Language.en.rawValue
        } else {
            return Language.en.rawValue
        }
    }
    
    private var appLocale: Locale {
        Locale(identifier: appLanguage)
    }
    
    private func localized(value: String, comment: String = "") -> String {
        guard let bundle = Bundle.main.path(forResource: appLanguage, ofType: "lproj") else {
            return NSLocalizedString(value, comment: comment)
        }
        
        let langBundle = Bundle(path: bundle)
        return NSLocalizedString(value, tableName: nil, bundle: langBundle!, comment: comment)
    }

}
