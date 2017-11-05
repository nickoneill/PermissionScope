//
//  PermissionScope+Reminders.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import EventKit

@objc public class RemindersPermission: NSObject, Permission {
	public let type: PermissionType = .reminders
}

extension PermissionScope {
	/**
	Requests access to Reminders, if necessary.
	*/
	public func requestReminders() {
		let status = statusReminders()
		switch status {
		case .unknown:
			EKEventStore().requestAccess(to: .reminder,
			                             completion: { granted, error in
											self.detectAndCallback()
			})
		case .unauthorized:
			self.showDeniedAlert(.reminders)
		default:
			break
		}
	}

	/**
	Returns the current permission status for accessing Reminders.

	- returns: Permission status for the requested type.
	*/
	public func statusReminders() -> PermissionStatus {
		let status = EKEventStore.authorizationStatus(for: .reminder)
		switch status {
		case .authorized:
			return .authorized
		case .restricted, .denied:
			return .unauthorized
		case .notDetermined:
			return .unknown
		}
	}

}
