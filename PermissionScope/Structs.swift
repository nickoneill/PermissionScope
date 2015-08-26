//
//  Structs.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation
import HealthKit

@objc public enum PermissionType: Int, Hashable {
    case Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events, Bluetooth, Motion, HealthKit(Set<HKSampleType>?, Set<HKObjectType>?)
    
    public var prettyDescription: String {
        switch self {
        case .LocationAlways, .LocationInUse:
            return "Location"
        default:
            return "\(self)"
        }
    }
    
    public var hashValue: Int {
        switch self {
        case HealthKit(let typesToShare, let typesToRead):
            return (typesToShare?.hashValue ?? 1) ^ (typesToRead?.hashValue ?? 1)
        default:
            return "\(self)".hashValue
        }
    }
    
    public var isHealthKit: Bool {
        if case .HealthKit = self {
            return true
        }
        return false
    }
    
    public var description: String {
        switch self {
        case .Contacts:         return "Contacts"
        case .Events:           return "Events"
        case .LocationAlways:   return "LocationAlways"
        case .LocationInUse:    return "LocationInUse"
        case .Notifications:    return "Notifications"
        case .Microphone:       return "Microphone"
        case .Camera:           return "Camera"
        case .Photos:           return "Photos"
        case .Reminders:        return "Reminders"
        case .Bluetooth:        return "Bluetooth"
        case .Motion:           return "Motion"
        case .HealthKit(_, _):  return "HealthKit"
        }
    }
    
    // Watch out for
    static let allValues = [Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events, Bluetooth, Motion]
}

@objc public enum PermissionStatus: Int, CustomStringConvertible {
    case Authorized, Unauthorized, Unknown, Disabled
    
    public var description: String {
        switch self {
        case .Authorized:   return "Authorized"
        case .Unauthorized: return "Unauthorized"
        case .Unknown:      return "Unknown"
        case .Disabled:     return "Disabled" // System-level
        }
    }
}

@objc public class PermissionConfig: NSObject {
    let type: PermissionType
    let message: String
    
    let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(type: PermissionType, message: String, notificationCategories: Set<UIUserNotificationCategory>? = .None) {
        if type != .Notifications && notificationCategories != .None {
            assertionFailure("notificationCategories only apply to the .Notifications permission")
        }
        
        self.type                   = type
        self.message                = message
        self.notificationCategories = notificationCategories
    }
}

@objc public class PermissionResult: NSObject {
    public let type: PermissionType
    public let status: PermissionStatus
    
    internal init(type:PermissionType, status:PermissionStatus) {
        self.type   = type
        self.status = status
    }
    
    override public var description: String {
        return "\(type) \(status)"
    }
}
