//
//  Localization.swift
//  Localization
//
//  Created by Stefano Venturin on 29/06/16.
//  Copyright (c) 2016 Stefano Venturin. All rights reserved.
//

import Foundation

// Internal current language key
let LCLCurrentLanguageKey = "LCLCurrentLanguageKey"

// Default language. English. If English is unavailable defaults to base localization.
let LCLDefaultLanguage = "en"

/// Base bundle as fallback.
let LCLBaseBundle = "Base"

// Name for language change notification
public let LCLLanguageChangeNotification = "LCLLanguageChangeNotification"


// MARK: Localization Syntax
public func LocalizedPlural(string: String, argument: CVarArgType) -> String {
    return string.localizedPlural(argument)
}


public extension String {
    /*
     Swift 2 friendly localization syntax, replaces NSLocalizedString
     - Returns: The localized string.
     */
    func localize() -> String {
        if let path = NSBundle.mainBundle().pathForResource(Localize.currentLanguage(), ofType: "lproj"), bundle = NSBundle(path: path) {
            return bundle.localizedStringForKey(self, value: nil, table: nil)
        }
        else if let path = NSBundle.mainBundle().pathForResource(LCLBaseBundle, ofType: "lproj"), bundle = NSBundle(path: path) {
            return bundle.localizedStringForKey(self, value: nil, table: nil)
        }
        return self
    }
    
    /*
     Swift 2 friendly localization syntax with format arguments, replaces String(format:NSLocalizedString)
     - Returns: The formatted localized string with arguments.
     */
    func localizedFormat(arguments: CVarArgType...) -> String {
        return String(format: localize(), arguments: arguments)
    }
    
    /*
     Swift 2 friendly plural localization syntax with a format argument
     
     - parameter argument: Argument to determine pluralisation
     
     - returns: Pluralized localized string.
     */
    func localizedPlural(argument: CVarArgType) -> String {
        return NSString.localizedStringWithFormat(localize(), argument) as String
    }
}



// MARK: Language Setting Functions

public class Localize: NSObject {
    
    /*
     List available languages
     - Returns: Array of available languages.
     */
    public class func availableLanguage(excludeBase: Bool = false) -> [String] {
        var availableLanguage = NSBundle.mainBundle().localizations
        // If excludeBase = true, don't include "Base" in available languages
        if let indexOfBase = availableLanguage.indexOf("Base") where excludeBase == true {
            availableLanguage.removeAtIndex(indexOfBase)
        }
        return availableLanguage
    }
    
    /*
     Current language
     - Returns: The current language. String.
     */
    public class func currentLanguage() -> String {
        if let currentLanguage = NSUserDefaults.standardUserDefaults().objectForKey(LCLCurrentLanguageKey) as? String {
            return currentLanguage
        }
        return defaultLanguage()
    }
    
    /*
     Change the current language
     - Parameter language: Desired language.
     */
    public class func setCurrentLanguage(language: String) {
        let selectedLanguage = availableLanguage().contains(language) ? language : defaultLanguage()
        if (selectedLanguage != currentLanguage()){
            NSUserDefaults.standardUserDefaults().setObject(selectedLanguage, forKey: LCLCurrentLanguageKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            NSNotificationCenter.defaultCenter().postNotificationName(LCLLanguageChangeNotification, object: nil)
        }
        
    }
    
    /*
     Default language
     - Returns: The app's default language. String.
     */
    public class func defaultLanguage() -> String {
        var defaultLanguage: String = String()
        guard let preferredLanguage = NSBundle.mainBundle().preferredLocalizations.first else {
            return LCLDefaultLanguage
        }
        let availableLanguages: [String] = self.availableLanguage()
        if (availableLanguages.contains(preferredLanguage)) {
            defaultLanguage = preferredLanguage
        }
        else {
            defaultLanguage = LCLDefaultLanguage
        }
        return defaultLanguage
    }
    
    /*
     Resets the current language to the default
     */
    public class func resetCurrentLanguageToDefault() {
        setCurrentLanguage(self.defaultLanguage())
    }
    
    /*
     Get the current language display name for a language.
     - Parameter language: Desired language.
     - Returns: The localized string.
     */
    public class func displayNameForLanguage(language: String) -> String {
        let locale : NSLocale = NSLocale(localeIdentifier: currentLanguage())
        if let displayName = locale.displayNameForKey(NSLocaleLanguageCode, value: language) {
            return displayName
        }
        return String()
    }
}


