//
//  Permissions.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/25/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation
import CoreLocation
import AddressBook
import AVFoundation
import Photos
import EventKit
import CoreBluetooth
import CoreMotion
import CloudKit
import Accounts

/**
*  Protocol for permission configurations.
*/
@objc public protocol Permission {
    /// Permission type
    var type: PermissionType { get }
}

@objc public class NotificationsPermission: NSObject, Permission {
    public let type: PermissionType = .Notifications
    public let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(notificationCategories: Set<UIUserNotificationCategory>? = nil) {
        self.notificationCategories = notificationCategories
    }
}

@objc public class LocationWhileInUsePermission: NSObject, Permission {
    public let type: PermissionType = .LocationInUse
}

@objc public class LocationAlwaysPermission: NSObject, Permission {
    public let type: PermissionType = .LocationAlways
}

@objc public class ContactsPermission: NSObject, Permission {
    public let type: PermissionType = .Contacts
}

public typealias requestPermissionUnknownResult = () -> Void
public typealias requestPermissionShowAlert     = (PermissionType) -> Void

@objc public class EventsPermission: NSObject, Permission {
    public let type: PermissionType = .Events
}

@objc public class MicrophonePermission: NSObject, Permission {
    public let type: PermissionType = .Microphone
}

@objc public class CameraPermission: NSObject, Permission {
    public let type: PermissionType = .Camera
}

@objc public class PhotosPermission: NSObject, Permission {
    public let type: PermissionType = .Photos
}

@objc public class RemindersPermission: NSObject, Permission {
    public let type: PermissionType = .Reminders
}

@objc public class BluetoothPermission: NSObject, Permission {
    public let type: PermissionType = .Bluetooth
}

@objc public class MotionPermission: NSObject, Permission {
    public let type: PermissionType = .Motion
}
