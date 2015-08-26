//
//  Extensions.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation
import HealthKit

extension UIColor {
    var inverseColor: UIColor{
        var r:CGFloat = 0.0; var g:CGFloat = 0.0; var b:CGFloat = 0.0; var a:CGFloat = 0.0;
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: 1.0-r, green: 1.0 - g, blue: 1.0 - b, alpha: a)
        }
        return self
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension SequenceType {
    // Ty https://bigonotetaking.wordpress.com/2015/08/22/using-higher-order-methods-everywhere/
    func first(@noescape pred: Generator.Element -> Bool) -> Generator.Element? {
        for x in self where pred(x) { return x }
        return nil
    }
}

extension Optional {
    var isNil: Bool {
        if let _ = self {
            return false
        }
        return true
    }
}

extension HKAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case NotDetermined: return "NotDetermined"
        case SharingDenied: return "SharingDenied"
        case SharingAuthorized: return "SharingAuthorized"
        }
    }
}
