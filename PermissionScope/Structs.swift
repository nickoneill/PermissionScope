//
//  Structs.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/21/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation
import HealthKit

@objc public enum PermissionType: Int {
    case Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events, Bluetooth, Motion, HealthKit(Set<HKSampleType>?, Set<HKObjectType>?)
    
    public var prettyDescription: String {
        switch self {
        case .LocationAlways, .LocationInUse:
            return "Location"
        default:
            return "\(self)"
        }
    }
    
    // Watch out for 
    static let allValues = [Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events, Bluetooth, Motion, HealthKit(nil, nil)]
    
}

@objc public enum PermissionStatus: Int {
    case Authorized, Unauthorized, Unknown, Disabled
}

@objc public enum PermissionDemands: Int {
    case Required, Optional
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
