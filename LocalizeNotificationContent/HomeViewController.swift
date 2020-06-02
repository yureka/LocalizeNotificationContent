//
//  HomeViewController.swift
//  LocalizeNotificationContent
//
//  Created by Yureka on 30/05/20.
//  Copyright © 2020 Yureka. All rights reserved.
//

import Foundation
import UIKit

class HomeViewController: UIViewController {
    
    @IBOutlet weak var labelSelectLanguageText: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Save device language to UserDefaults
        if #available(iOS 13, *) {
            LanguageManager.shared.currentLanguage = LanguageManager.shared.deviceLanguage ?? .en
        }
        
        // Localize the text programatically and bind to label
        labelSelectLanguageText.text = "Please select your language preference below to change app language".localized()
    }
    
    @IBAction func buttonLanguageClickAction(_ sender: UIButton) {
        if #available(iOS 13, *) {
            // Open app settings to change the current app language
            let url = URL(string: UIApplication.openSettingsURLString)!
            UIApplication.shared.open(url)
        } else {
            // Force change the app language with the combination of swizzling these 2 methods
            // #awakeFromNib and #myLocaLizedString(forKey:value:table:)
            var selectedLanguage = Language.en
            switch sender.tag {
            case 1:
                selectedLanguage = Language.zhHans
            case 2:
                selectedLanguage = Language.es
            default:
                selectedLanguage = Language.en
            }
            forceChangeLanguage(to: selectedLanguage)
        }
    }
    
    private func forceChangeLanguage(to selectedLanguage: Language) {
        
        let langaugeManager = LanguageManager.shared

        if langaugeManager.currentLanguage.rawValue != selectedLanguage.rawValue {
            langaugeManager.removeDefaultLanguage()
            langaugeManager.defaultLanguage = selectedLanguage
            
            // swizzling the method #myLocaLizedString(forKey:value:table:)
            langaugeManager.setAppleLanguagePref(with: selectedLanguage)
            
            langaugeManager.setLanguage(language: selectedLanguage,
                                               viewControllerFactory: { title -> UIViewController in
                                                // the view controller that you want to show after changing the language
                                                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                                                return storyboard.instantiateInitialViewController()!
            }) { view in
                view.transform = CGAffineTransform(scaleX: 2, y: 2)
                view.alpha = 0
            }
        }
    }
}
