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

@objc open class NotificationsPermission: NSObject, Permission {
    open let type: PermissionType = .notifications
    open let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(notificationCategories: Set<UIUserNotificationCategory>? = nil) {
        self.notificationCategories = notificationCategories
    }
}

@objc open class LocationWhileInUsePermission: NSObject, Permission {
    open let type: PermissionType = .locationInUse
}

@objc open class LocationAlwaysPermission: NSObject, Permission {
    open let type: PermissionType = .locationAlways
}

@objc open class ContactsPermission: NSObject, Permission {
    open let type: PermissionType = .contacts
}

public typealias requestPermissionUnknownResult = () -> Void
public typealias requestPermissionShowAlert     = (PermissionType) -> Void

@objc open class EventsPermission: NSObject, Permission {
    open let type: PermissionType = .events
}

@objc open class MicrophonePermission: NSObject, Permission {
    open let type: PermissionType = .microphone
}

@objc open class CameraPermission: NSObject, Permission {
    open let type: PermissionType = .camera
}

@objc open class PhotosPermission: NSObject, Permission {
    open let type: PermissionType = .photos
}

@objc open class RemindersPermission: NSObject, Permission {
    open let type: PermissionType = .reminders
}

@objc open class BluetoothPermission: NSObject, Permission {
    open let type: PermissionType = .bluetooth
}

@objc open class MotionPermission: NSObject, Permission {
    open let type: PermissionType = .motion
}
