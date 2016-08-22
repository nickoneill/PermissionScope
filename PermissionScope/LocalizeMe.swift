//
//  LocalizeMe.swift
//  LocalizeMe
//
//  Created by Stefano Venturin on 29/06/16.
//  Copyright (c) 2016 Stefano Venturin. All rights reserved.
//

import Foundation

let LCLCurrentLanguageKey = "LCLCurrentLanguageKey"
let LCLDefaultLanguage = "en"
let LCLBaseBundle = "Base"

public extension String {
    /* Return the localized string  */
    func localizeMe() -> String {
        if let path = NSBundle.mainBundle().pathForResource(LocalizeMe.currentLanguages(), ofType: "lproj"), bundle = NSBundle(path: path) {
            return bundle.localizedStringForKey(self, value: nil, table: nil)
        } else if let path = NSBundle.mainBundle().pathForResource(LCLBaseBundle, ofType: "lproj"), bundle = NSBundle(path: path) {
            return bundle.localizedStringForKey(self, value: nil, table: nil)
        }
        return self
    }
}

public class LocalizeMe:NSObject {
    /* Return an array of available languages */
    public class func availableLanguage(excludeBase: Bool = false) -> [String] {
        var availableLanguage = NSBundle.mainBundle().localizations
        // Don't include 'Base' languages if 'excludeBase' is true 
        if let indexOfBase = availableLanguage.indexOf("Base") where excludeBase == true {
            availableLanguage.removeAtIndex(indexOfBase)
        }
        return availableLanguage
    }
    
    /* Return the current language as String */
    public class func currentLanguages() -> String {
        if let currentLanguage = NSUserDefaults.standardUserDefaults().objectForKey(LCLCurrentLanguageKey) as? String {
            return currentLanguage
        }
        return defaultLanguage()
    }
    
    /* Return the app default language as String */
    public class func defaultLanguage() -> String {
        var defaultLanguage: String = String()
        guard let preferredLanguage = NSBundle.mainBundle().preferredLocalizations.first else {
            return LCLDefaultLanguage
        }
        
        let availableLanguages: [String] = self.availableLanguage()
        if (availableLanguages.contains(preferredLanguage)) {
            defaultLanguage = preferredLanguage
        } else { defaultLanguage = LCLDefaultLanguage }
        return defaultLanguage
    }
}
