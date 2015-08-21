//
//  Structs.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation

@objc public enum PermissionType: Int, CustomStringConvertible {
    case Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events, Bluetooth, Motion
    
    public var prettyDescription: String {
        switch self {
        case .LocationAlways, .LocationInUse:
            return "Location"
        default:
            return "\(self)"
        }
    }
    
    public var description: String {
        switch self {
        case .Contacts: return "Contacts"
        case .Events: return "Events"
        case .LocationAlways: return "LocationAlways"
        case .LocationInUse: return "LocationInUse"
        case .Notifications: return "Notifications"
        case .Microphone: return "Microphone"
        case .Camera: return "Camera"
        case .Photos: return "Photos"
        case .Reminders: return "Reminders"
        case .Bluetooth: return "Bluetooth"
        case .Motion: return "Motion"
        }
    }
    
    // Watch out for
    static let allValues = [Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events, Bluetooth, Motion]
    
}

@objc public enum PermissionStatus: Int, CustomStringConvertible {
    case Authorized, Unauthorized, Unknown, Disabled
    
    public var description: String {
        switch self {
        case .Authorized: return "Authorized"
        case .Unauthorized:return "Unauthorized"
        case .Unknown: return "Unknown"
        case .Disabled: return "Disabled" // System-level
        }
    }
}

@objc public enum PermissionDemands: Int, CustomStringConvertible {
    case Required, Optional
    
    public var description: String {
        switch self {
        case .Required: return "Required"
        case .Optional: return "Optional"
        }
    }
}

@objc public class PermissionConfig: NSObject {
    let type: PermissionType
    let demands: PermissionDemands
    let message: String
    
    let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(type: PermissionType, demands: PermissionDemands, message: String, notificationCategories: Set<UIUserNotificationCategory>? = .None) {
        if type != .Notifications && notificationCategories != .None {
            assertionFailure("notificationCategories only apply to the .Notifications permission")
        }
        
        self.type = type
        self.demands = demands
        self.message = message
        self.notificationCategories = notificationCategories
    }
}

@objc public class PermissionResult: NSObject {
    public let type: PermissionType
    public let status: PermissionStatus
    public let demands: PermissionDemands
    
    internal init(type:PermissionType, status:PermissionStatus, demands:PermissionDemands) {
        self.type = type
        self.status = status
        self.demands = demands
    }
    
    override public var description: String {
        return "\(type) \(status)"
    }
}
