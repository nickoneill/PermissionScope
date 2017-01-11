//
//  PermissionScope+Motion.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import CoreMotion

private var motionManagerKey: UInt8 = 0

@objc public class MotionPermission: NSObject, Permission {
	public let type: PermissionType = .motion
}

extension PermissionScope {
	var motionManager:CMMotionActivityManager {
		get {
			if let man = objc_getAssociatedObject(self, &motionManagerKey) as? CMMotionActivityManager {
				return man
			}
			let man = CMMotionActivityManager()
			objc_setAssociatedObject(self, &motionManagerKey, man, .OBJC_ASSOCIATION_RETAIN)
			return man
		}
		set {
		}
	}

	/**
	Returns the current permission status for accessing Core Motion Activity.

	- returns: Permission status for the requested type.
	*/
	public func statusMotion() -> PermissionStatus {
		if askedMotion {
			triggerMotionStatusUpdate()
		}
		return motionPermissionStatus
	}

	/**
	Requests access to Core Motion Activity, if necessary.
	*/
	public func requestMotion() {
		let status = statusMotion()
		switch status {
		case .unauthorized:
			showDeniedAlert(.motion)
		case .unknown:
			triggerMotionStatusUpdate()
		default:
			break
		}
	}

	/**
	Prompts motionManager to request a status update. If permission is not already granted the user will be prompted with the system's permission dialog.
	*/
	fileprivate func triggerMotionStatusUpdate() {
		let tmpMotionPermissionStatus = motionPermissionStatus
		defaults.set(true, forKey: Constants.NSUserDefaultsKeys.requestedMotion)
		defaults.synchronize()

		let today = Date()
		motionManager.queryActivityStarting(from: today,
		                                    to: today,
		                                    to: .main) { activities, error in
												if let error = error , error._code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
													self.motionPermissionStatus = .unauthorized
												} else {
													self.motionPermissionStatus = .authorized
												}

												self.motionManager.stopActivityUpdates()
												if tmpMotionPermissionStatus != self.motionPermissionStatus {
													self.waitingForMotion = false
													self.detectAndCallback()
												}
		}

		askedMotion = true
		waitingForMotion = true
	}
}
