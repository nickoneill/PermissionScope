//
//  PermissionScope+Notifications.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation

@objc public class NotificationsPermission: NSObject, Permission {
	public let type: PermissionType = .notifications
	public var status: PermissionStatus {
		get {
			let settings = UIApplication.shared.currentUserNotificationSettings
			if let settingTypes = settings?.types , settingTypes != UIUserNotificationType() {
				return .authorized
			} else {
				if UserDefaults.standard.bool(forKey: Constants.NSUserDefaultsKeys.requestedNotifications) {
					return .unauthorized
				} else {
					return .unknown
				}
			}
		}
	}

	public let notificationCategories: Set<UIUserNotificationCategory>?

	public init(notificationCategories: Set<UIUserNotificationCategory>? = nil) {
		self.notificationCategories = notificationCategories
	}
}

extension PermissionScope {
	/**
	Requests access to User Notifications, if necessary.
	*/
	public func requestNotifications() {

		let status = statusNotifications()
		switch status {
		case .unknown:
			let notificationsPermission = self.configuredPermissions
				.first { $0 is NotificationsPermission } as? NotificationsPermission
			let notificationsPermissionSet = notificationsPermission?.notificationCategories

			NotificationCenter.default.addObserver(self, selector: #selector(showingNotificationPermission), name: NSNotification.Name.UIApplicationWillResignActive, object: nil)

			notificationTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(finishedShowingNotificationPermission), userInfo: nil, repeats: false)

			UIApplication.shared.registerUserNotificationSettings(
				UIUserNotificationSettings(types: [.alert, .sound, .badge],
				                           categories: notificationsPermissionSet)
			)
		case .unauthorized:
			showDeniedAlert(.notifications)
		case .disabled:
			showDisabledAlert(.notifications)
		case .authorized:
			detectAndCallback()
		}
	}

	/**
	Returns the current permission status for accessing Notifications.

	- returns: Permission status for the requested type.
	*/
	public func statusNotifications() -> PermissionStatus {
		let perm = NotificationsPermission()
		return perm.status
	}
}
