//
//  Structs.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation

/// Permissions currently supportes by PermissionScope
@objc public enum PermissionType: Int, CustomStringConvertible {
    #if PermissionScopeRequestContactsEnabled
    case contacts
    #endif
    #if PermissionScopeRequestLocationEnabled
    case locationAlways
    case locationInUse
    #endif
    #if PermissionScopeRequestNotificationsEnabled
    case notifications
    #endif
    #if PermissionScopeRequestMicrophoneEnabled
    case microphone
    #endif
    #if PermissionScopeRequestCameraEnabled
    case camera
    #endif
    #if PermissionScopeRequestPhotoLibraryEnabled
    case photos
    #endif
    #if PermissionScopeRequestRemindersEnabled
    case reminders
    #endif
    #if PermissionScopeRequestEventsEnabled
    case events
    #endif
    #if PermissionScopeRequestBluetoothEnabled
    case bluetooth
    #endif
    #if PermissionScopeRequestMotionEnabled
    case motion
    #endif
    
    public var prettyDescription: String {
        // TODO:  This will not compile due to same problem described below.
        switch self {
        case .locationAlways, .locationInUse:
            return "Location"
        default:
            return "\(self)"
        }
    }
    
    public var description: String {
        /* TODO: This will not compile when used in a project (unless project is asking ALL permissions) because any permission that is not used will have it's enum undefined due to the #ifendif statements around the enum definition above.
        */
        switch self {
        case .contacts:         return "Contacts"
        case .events:           return "Events"
        case .locationAlways:   return "LocationAlways"
        case .locationInUse:    return "LocationInUse"
        case .notifications:    return "Notifications"
        case .microphone:       return "Microphone"
        case .camera:           return "Camera"
        case .photos:           return "Photos"
        case .reminders:        return "Reminders"
        case .bluetooth:        return "Bluetooth"
        case .motion:           return "Motion"
        }
    }
    
    static var allValues: [PermissionType] {
        var values = [PermissionType]()
        for permission in iterateEnum(PermissionType.self) {
            guard let permissionType = PermissionType(rawValue: permission.rawValue) else { continue }
            values.append(permissionType)
        }
        return values
    }
}

/// Possible statuses for a permission.
@objc public enum PermissionStatus: Int, CustomStringConvertible {
    case authorized, unauthorized, unknown, disabled
    
    public var description: String {
        switch self {
        case .authorized:   return "Authorized"
        case .unauthorized: return "Unauthorized"
        case .unknown:      return "Unknown"
        case .disabled:     return "Disabled" // System-level
        }
    }
}

/// Result for a permission status request.
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

/* Used to iterate through available PermissionType based on permissions in use.  Taken from http://stackoverflow.com/a/28341290/3880396 */
func iterateEnum<T: Hashable>(_: T.Type) -> AnyIterator<T> {
    var i = 0
    return AnyIterator {
        let next = withUnsafePointer(to: &i) {
            $0.withMemoryRebound(to: T.self, capacity: 1) { $0.pointee }
        }
        if next.hashValue != i { return nil }
        i += 1
        return next
    }
}
