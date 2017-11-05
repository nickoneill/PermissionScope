//
//  PermissionScope+Events.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import EventKit

@objc public class EventsPermission: NSObject, Permission {
	public let type: PermissionType = .events
}


extension PermissionScope {
	/**
	Requests access to Events, if necessary.
	*/
	public func requestEvents() {
		let status = statusEvents()
		switch status {
		case .unknown:
			EKEventStore().requestAccess(to: .event,
			                             completion: { granted, error in
											self.detectAndCallback()
			})
		case .unauthorized:
			self.showDeniedAlert(.events)
		default:
			break
		}
	}

	/**
	Returns the current permission status for accessing Events.

	- returns: Permission status for the requested type.
	*/
	public func statusEvents() -> PermissionStatus {
		let status = EKEventStore.authorizationStatus(for: .event)
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
