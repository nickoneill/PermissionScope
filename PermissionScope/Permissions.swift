//
//  Permissions.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 8/25/15.
//  Copyright © 2015 That Thing in Swift. All rights reserved.
//

import Foundation

/**
*  Protocol for permission configurations.
*/
@objc public protocol Permission {
    /// Permission type
    var type: PermissionType { get }
}

#if PermissionScopeRequestNotificationsEnabled
@objc public class NotificationsPermission: NSObject, Permission {
    public let type: PermissionType = .notifications
    public let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(notificationCategories: Set<UIUserNotificationCategory>? = nil) {
        self.notificationCategories = notificationCategories
    }
}
#endif

#if PermissionScopeRequestLocationEnabled
@objc public class LocationWhileInUsePermission: NSObject, Permission {
    public let type: PermissionType = .locationInUse
}
#endif

#if PermissionScopeRequestLocationEnabled
@objc public class LocationAlwaysPermission: NSObject, Permission {
    public let type: PermissionType = .locationAlways
}
#endif

#if PermissionScopeRequestContactsEnabled
@objc public class ContactsPermission: NSObject, Permission {
    public let type: PermissionType = .contacts
}
#endif

public typealias requestPermissionUnknownResult = () -> Void
public typealias requestPermissionShowAlert     = (PermissionType) -> Void

#if PermissionScopeRequestEventsEnabled
@objc public class EventsPermission: NSObject, Permission {
    public let type: PermissionType = .events
}
#endif

#if PermissionScopeRequestMicrophoneEnabled
@objc public class MicrophonePermission: NSObject, Permission {
    public let type: PermissionType = .microphone
}
#endif

#if PermissionScopeRequestCameraEnabled
@objc public class CameraPermission: NSObject, Permission {
    public let type: PermissionType = .camera
}
#endif

#if PermissionScopeRequestPhotoLibraryEnabled
@objc public class PhotosPermission: NSObject, Permission {
    public let type: PermissionType = .photos
}
#endif

#if PermissionScopeRequestRemindersEnabled
@objc public class RemindersPermission: NSObject, Permission {
    public let type: PermissionType = .reminders
}
#endif

#if PermissionScopeRequestBluetoothEnabled
@objc public class BluetoothPermission: NSObject, Permission {
    public let type: PermissionType = .bluetooth
}
#endif

#if PermissionScopeRequestMotionEnabled
@objc public class MotionPermission: NSObject, Permission {
    public let type: PermissionType = .motion
}
#endif
