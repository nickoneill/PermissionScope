//
//  Constants.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation

enum Constants {
    struct UI {
        static let contentWidth: CGFloat = 280.0
        static let dialogHeightTwoPermissions: CGFloat = 360
        static let dialogHeightThreePermissions: CGFloat = 460
        static let dialogHeightSinglePermission: CGFloat = 260
    }
    
    struct NSUserDefaultsKeys {
        static let requestedInUseToAlwaysUpgrade = "requestedInUseToAlwaysUpgrade"
        static let requestedForBluetooth = "askedForBluetooth"
        static let requestedForMotion = "askedForMotion"
        static let askedForNotificationsDefaultsKey = "PermissionScopeAskedForNotificationsDefaultsKey"
    }
}
