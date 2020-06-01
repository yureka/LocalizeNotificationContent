//
//  LanguageManagerModels.swift
//  LocalizeNotificationContent
//
//  Created by Yureka on 30/05/20.
//  Copyright © 2020 Yureka. All rights reserved.
//

import Foundation

import Foundation

enum LanguageManagerKeys {
    static let selectedLanguage = "LanguageManagerSelectedLanguage"
    static let defaultLanguage = "LanguageManagerDefaultLanguage"
    static let applePreferenceKey = "AppleLanguage"
    static let isFirstRun = "isFirstRun"
}

public enum Language: String, CaseIterable {
    case en, es, hi
    case zhHans = "zh-Hans"
    case deviceLanguage
    
    var name: String {
        switch self {
        case .en:
            return "English"
        case .es:
            return "Spanish"
        case .zhHans:
            return "Chinese, Simplified"
        case .hi:
            return "Hindi"
        default:
            return "English"
        }
    }
}
