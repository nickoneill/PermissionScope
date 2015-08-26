//
//  PermissionConfigs.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/25/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation
import HealthKit
import Accounts

@objc public protocol PermissionConfig {
    var type: PermissionType { get }
    var message: String { get }
}

@objc public class NotificationsPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType
    public let message: String
    public let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(message: String, notificationCategories: Set<UIUserNotificationCategory>? = .None) {
        self.notificationCategories = notificationCategories
        self.type                   = .Notifications
        self.message                = message
    }
}

@objc public class HealthPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .HealthKit
    public let message: String
    public let healthTypesToShare: Set<HKSampleType>?
    public let healthTypesToRead: Set<HKObjectType>?
    
    public init(message: String, healthTypesToShare: Set<HKSampleType>?,
        healthTypesToRead: Set<HKObjectType>?) {
            self.healthTypesToShare = healthTypesToShare
            self.healthTypesToRead = healthTypesToRead
            self.message = message
    }
}

@objc public class LocationWhileInUsePermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .LocationInUse
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class LocationAlwaysPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .LocationAlways
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class ContactsPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Contacts
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class EventsPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Events
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class MicrophonePermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Microphone
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class CameraPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Camera
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class PhotosPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Photos
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class RemindersPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Reminders
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class BluetoothPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Bluetooth
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}

@objc public class MotionPermissionConfig: NSObject, PermissionConfig {
    public let type: PermissionType = .Motion
    public let message: String
    
    public init(message: String) {
        self.message = message
    }
}
