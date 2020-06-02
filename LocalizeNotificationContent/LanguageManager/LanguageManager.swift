//
//  LanguageManager.swift
//  LocalizeNotificationContent
//
//  Created by Yureka on 30/05/20.
//  Copyright © 2020 Yureka. All rights reserved.
//

import Foundation
import UIKit

public class LanguageManager {
    
    public typealias Animation = ((UIView) -> Void)
    public typealias ViewControllerFactory = ((String?) -> UIViewController)
    public typealias WindowAndTitle = (UIWindow?, String?)
    
    public static let shared: LanguageManager = LanguageManager()
    
    // Shared UserDefaults created in app group
    let userDefault = UserDefaults(suiteName: "group.localized")
    
    public var currentLanguage: Language {
        get {
            guard let currentLang = userDefault?.string(forKey: LanguageManagerKeys.selectedLanguage) else {
                return deviceLanguage ?? .en
            }
            return Language(rawValue: currentLang)!
        }
        set {
            userDefault?.set(newValue.rawValue, forKey: LanguageManagerKeys.selectedLanguage)
        }
    }
    
    // The default language that the app will run first time.
    // You need to set the `defaultLanguage` in the `AppDelegate`, specifically in
    // the first line inside `application(_:willFinishLaunchingWithOptions:)`.
    public var defaultLanguage: Language {
        get {
            guard let defaultLanguage = userDefault?.string(forKey: LanguageManagerKeys.defaultLanguage) else {
                fatalError("Did you set the default language for the app?")
            }
            return Language(rawValue: defaultLanguage)!
        }
        set {
            
            if Constant.OS_VERSION_NUMBER < 13.0 {
            // swizzle the awakeFromNib from nib and localize the text in the new awakeFromNib
                UIView.localize()
            }
            
            let defaultLanguage = userDefault?.string(forKey: LanguageManagerKeys.defaultLanguage)
            guard defaultLanguage == nil else {
                setLanguage(language: currentLanguage)
                userDefault?.set(currentLanguage.rawValue, forKey: LanguageManagerKeys.defaultLanguage)
                return
            }
            
            var language = newValue
            if language == .deviceLanguage {
                language = deviceLanguage ?? .en
            }
            
            userDefault?.set(language.rawValue, forKey: LanguageManagerKeys.defaultLanguage)
            
            setLanguage(language: language)
        }
    }
    
    func setAppleLanguagePref(with language: Language) {
        userDefault?.set(language.rawValue, forKey: LanguageManagerKeys.applePreferenceKey)
        (UIApplication.shared.delegate as! AppDelegate).currentLanguage = language.rawValue
        Bundle.swizzleLocalization()
    }
    
    // The device language is different than the app language,
    // to get the app language use `currentLanguage`.
    public var deviceLanguage: Language? {
        get {
            guard let deviceLanguage = Bundle.main.preferredLocalizations.first else {
                return nil
            }
            return Language(rawValue: deviceLanguage)
        }
    }
    
    // The direction of the language.
    public var isRightToLeft: Bool {
        get {
            return isLanguageRightToLeft(language: currentLanguage)
        }
    }
    
    // The app locale to use it in dates and currency.
    public var appLocale: Locale {
        get {
            return Locale(identifier: currentLanguage.rawValue)
        }
    }
    
    ///
    /// Set the current language of the app
    ///
    /// - parameter language: The language that you need the app to run with.
    /// - parameter windows: The windows you want to change the `rootViewController` for. if you didn't
    ///                      set it, it will change the `rootViewController` for all the windows in the
    ///                      scenes.
    /// - parameter viewControllerFactory: A closure to make the `ViewController` for a specific `scene`, you can know for which
    ///                                    `scene` you need to make the controller you can check the `title` sent to this clouser,
    ///                                    this title is the `title` of the `scene`, so if there is 5 scenes this closure will get called 5 times
    ///                                    for each scene window.
    /// - parameter animation: A closure with the current view to animate to the new view controller,
    ///                        so you need to animate the view, move it out of the screen, change the alpha,
    ///                        or scale it down to zero.
    ///
    public func setLanguage(language: Language,
                            for windows: [WindowAndTitle]? = nil,
                            viewControllerFactory: ViewControllerFactory? = nil,
                            animation: Animation? = nil) {
        
        currentLanguage = language

        if Constant.OS_VERSION_NUMBER < 13.0 {
            changePreference(language)
            
            guard let viewControllerFactory = viewControllerFactory else {
                return
            }
            
            let windowsToChange = getWindowsToChangeFrom(windows)
            
            windowsToChange?.forEach({ windowAndTitle in
                let (window, title) = windowAndTitle
                let viewController = viewControllerFactory(title)
                changeViewController(for: window,
                                     rootViewController: viewController,
                                     animation: animation)
            })
        }
    }
    
    private func changePreference(_ language: Language) {
        // change the direction of the views
        let semanticContentAttribute: UISemanticContentAttribute = isLanguageRightToLeft(language: language) ? .forceRightToLeft : .forceLeftToRight
        UIView.appearance().semanticContentAttribute = semanticContentAttribute
    }
    
    private func getWindowsToChangeFrom(_ windows: [WindowAndTitle]?) -> [WindowAndTitle]? {
        var windowsToChange: [WindowAndTitle]?
        if let windows = windows {
            windowsToChange = windows
        } else {
            if #available(iOS 13.0, *) {
                windowsToChange = UIApplication.shared.connectedScenes
                    .compactMap({$0 as? UIWindowScene})
                    .map({ ($0.windows.first, $0.title) })
            } else {
                windowsToChange = [(UIApplication.shared.keyWindow, nil)]
            }
        }
        
        return windowsToChange
    }
    
    private func changeViewController(for window: UIWindow?,
                                      rootViewController: UIViewController,
                                      animation: Animation? = nil) {
        guard let snapshot = window?.snapshotView(afterScreenUpdates: true) else {
            return
        }
        rootViewController.view.addSubview(snapshot);
        
        window?.rootViewController = rootViewController
        
        UIView.animate(withDuration: 0.5, animations: {
            animation?(snapshot)
        }) { _ in
            snapshot.removeFromSuperview()
        }
    }
    
    private func isLanguageRightToLeft(language: Language) -> Bool {
        return Locale.characterDirection(forLanguage: language.rawValue) == .rightToLeft
    }
    
    func removeDefaultLanguage() {
        userDefault?.removeObject(forKey: LanguageManagerKeys.defaultLanguage)
    }
    
    func resetLanguagePreferences() {
        userDefault?.removeObject(forKey: LanguageManagerKeys.selectedLanguage)
        userDefault?.removeObject(forKey: LanguageManagerKeys.defaultLanguage)
        userDefault?.removeObject(forKey: LanguageManagerKeys.applePreferenceKey)
        
        LanguageManager.shared.defaultLanguage = LanguageManager.shared.currentLanguage
        
        if Constant.OS_VERSION_NUMBER < 13.0 {
            LanguageManager.shared.setAppleLanguagePref(with: LanguageManager.shared.currentLanguage)
        }
    }
    
    func isFirstLaunch() -> Bool {
        if !(userDefault?.bool(forKey: LanguageManagerKeys.isFirstRun) ?? false) {
            userDefault?.set(true, forKey: LanguageManagerKeys.isFirstRun)
            userDefault?.synchronize()
            return true
        }
        return false
    }
}

// MARK: - Swizzling
fileprivate extension UIView {
    
    static func removeSwizzling() {
        let originalSelector = #selector(swizzledAwakeFromNib)
        let swizzledSelector = #selector(awakeFromNib)
        
        let orginalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(orginalMethod!), method_getTypeEncoding(orginalMethod!))
        } else {
            method_exchangeImplementations(orginalMethod!, swizzledMethod!)
        }
    }
    
    static func localize() {
        
        let originalSelector = #selector(awakeFromNib)
        let swizzledSelector = #selector(swizzledAwakeFromNib)
        
        let orginalMethod = class_getInstanceMethod(self, originalSelector)
        let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
        
        let didAddMethod = class_addMethod(self, originalSelector, method_getImplementation(swizzledMethod!), method_getTypeEncoding(swizzledMethod!))
        
        if didAddMethod {
            class_replaceMethod(self, swizzledSelector, method_getImplementation(orginalMethod!), method_getTypeEncoding(orginalMethod!))
        } else {
            removeSwizzling()
            method_exchangeImplementations(orginalMethod!, swizzledMethod!)
        }
        
    }
    
    @objc func swizzledAwakeFromNib() {
        swizzledAwakeFromNib()
        
        switch self {
        case let txtf as UITextField:
            txtf.text = txtf.text?.localized()
            txtf.placeholder = txtf.placeholder?.localized()
        case let lbl as UILabel:
            lbl.text = lbl.text?.localized()
        case let tabbar as UITabBar:
            tabbar.items?.forEach({ $0.title = $0.title?.localized() })
        case let btn as UIButton:
            btn.setTitle(btn.title(for: .normal)?.localized(), for: .normal)
        case let sgmnt as UISegmentedControl:
            (0 ..< sgmnt.numberOfSegments).forEach { sgmnt.setTitle(sgmnt.titleForSegment(at: $0)?.localized(), forSegmentAt: $0) }
        case let txtv as UITextView:
            txtv.text = txtv.text?.localized()
        default:
            break
        }
    }
}

// MARK: - ImageDirection

public enum ImageDirection: Int {
    case fixed, leftToRight, rightToLeft
}

private extension UIView {
    ///
    /// Change the direction of the image depeneding in the language, there is no return value for this variable.
    /// The expectid values:
    ///
    /// -`fixed`: if the image must not change the direction depending on the language you need to set the value as 0.
    ///
    /// -`leftToRight`: if the image must change the direction depending on the language
    /// and the image is left to right image then you need to set the value as 1.
    ///
    /// -`rightToLeft`: if the image must change the direction depending on the language
    /// and the image is right to left image then you need to set the value as 2.
    ///
    var direction: ImageDirection {
        set {
            switch newValue {
            case .fixed:
                break
            case .leftToRight where LanguageManager.shared.isRightToLeft:
                transform = CGAffineTransform(scaleX: -1, y: 1)
            case .rightToLeft where !LanguageManager.shared.isRightToLeft:
                transform = CGAffineTransform(scaleX: -1, y: 1)
            default:
                break
            }
        }
        get {
            fatalError("There is no value return from this variable, this variable used to change the image direction depending on the langauge")
        }
    }
}

@IBDesignable
public extension UIImageView {
    ///
    /// Change the direction of the image depeneding in the language, there is no return value for this variable.
    /// The expectid values:
    ///
    /// -`fixed`: if the image must not change the direction depending on the language you need to set the value as 0.
    ///
    /// -`leftToRight`: if the image must change the direction depending on the language
    /// and the image is left to right image then you need to set the value as 1.
    ///
    /// -`rightToLeft`: if the image must change the direction depending on the language
    /// and the image is right to left image then you need to set the value as 2.
    ///
    @IBInspectable var imageDirection: Int {
        set {
            direction = ImageDirection(rawValue: newValue)!
        }
        get {
            return direction.rawValue
        }
    }
}

@IBDesignable
public extension UIButton {
    ///
    /// Change the direction of the image depeneding in the language, there is no return value for this variable.
    /// The expectid values:
    ///
    /// -`fixed`: if the image must not change the direction depending on the language you need to set the value as 0.
    ///
    /// -`leftToRight`: if the image must change the direction depending on the language
    /// and the image is left to right image then you need to set the value as 1.
    ///
    /// -`rightToLeft`: if the image must change the direction depending on the language
    /// and the image is right to left image then you need to set the value as 2.
    ///
    @IBInspectable var imageDirection: Int {
        set {
            direction = ImageDirection(rawValue: newValue)!
        }
        get {
            return direction.rawValue
        }
    }
}
