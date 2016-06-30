//
//  Extensions.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {
    /// Returns the inverse color
    var inverseColor: UIColor{
        var r:CGFloat = 0.0; var g:CGFloat = 0.0; var b:CGFloat = 0.0; var a:CGFloat = 0.0;
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: 1.0-r, green: 1.0 - g, blue: 1.0 - b, alpha: a)
        }
        return self
    }
}

extension String {
    /// NSLocalizedString shorthand
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension SequenceType {
    /**
    Returns the first that satisfies the predicate includeElement, or nil. Similar to `filter` but stops when one element is found. Thanks to [bigonotetaking](https://bigonotetaking.wordpress.com/2015/08/22/using-higher-order-methods-everywhere/)
    
    - parameter includeElement: Predicate that the Element must satisfy.
    
    - returns: First element that satisfies the predicate, or nil.
    */
    func first(@noescape includeElement: Generator.Element -> Bool) -> Generator.Element? {
        for x in self where includeElement(x) { return x }
        return nil
    }
}

extension Optional {
    /// True if the Optional is .None. Useful to avoid if-let.
    var isNil: Bool {
        if case .None = self {
            return true
        }
        return false
    }
}
