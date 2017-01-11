//
//  PermissionScope+Location.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import CoreLocation

@objc public class LocationWhileInUsePermission: NSObject, Permission, CLLocationManagerDelegate {
	public let type: PermissionType = .locationInUse
}

@objc public class LocationAlwaysPermission: NSObject, Permission, CLLocationManagerDelegate {
	public let type: PermissionType = .locationAlways
}

private var locationManagerKey: UInt8 = 0

extension PermissionScope: CLLocationManagerDelegate {
	var locationManager: CLLocationManager {
		get {
			if let man = objc_getAssociatedObject(self, &locationManagerKey) as? CLLocationManager {
				return man
			}
			let man = CLLocationManager()
			man.delegate = self
			objc_setAssociatedObject(self, &locationManagerKey, man, .OBJC_ASSOCIATION_RETAIN)
			return man
		}
		set {
		}
	}
	public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		detectAndCallback()
	}

	/**
	Requests access to LocationWhileInUse, if necessary.
	*/
	public func requestLocationInUse() {
		let hasWhenInUseKey :Bool = !Bundle.main
			.object(forInfoDictionaryKey: Constants.InfoPlistKeys.locationWhenInUse).isNil
		assert(hasWhenInUseKey, Constants.InfoPlistKeys.locationWhenInUse + " not found in Info.plist.")

		let status = statusLocationInUse()
		switch status {
		case .unknown:
			locationManager.requestWhenInUseAuthorization()
		case .unauthorized:
			self.showDeniedAlert(.locationInUse)
		case .disabled:
			self.showDisabledAlert(.locationInUse)
		default:
			break
		}
	}

	/**
	Returns the current permission status for accessing LocationWhileInUse.

	- returns: Permission status for the requested type.
	*/
	public func statusLocationInUse() -> PermissionStatus {
		guard CLLocationManager.locationServicesEnabled() else { return .disabled }

		let status = CLLocationManager.authorizationStatus()
		// if you're already "always" authorized, then you don't need in use
		// but the user can still demote you! So I still use them separately.
		switch status {
		case .authorizedWhenInUse, .authorizedAlways:
			return .authorized
		case .restricted, .denied:
			return .unauthorized
		case .notDetermined:
			return .unknown
		}
	}

	/**
	Requests access to LocationAlways, if necessary.
	*/
	public func requestLocationAlways() {
		let hasAlwaysKey:Bool = !Bundle.main
			.object(forInfoDictionaryKey: Constants.InfoPlistKeys.locationAlways).isNil
		assert(hasAlwaysKey, Constants.InfoPlistKeys.locationAlways + " not found in Info.plist.")

		let status = statusLocationAlways()
		switch status {
		case .unknown:
			if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
				defaults.set(true, forKey: Constants.NSUserDefaultsKeys.requestedInUseToAlwaysUpgrade)
				defaults.synchronize()
			}
			locationManager.requestAlwaysAuthorization()
		case .unauthorized:
			self.showDeniedAlert(.locationAlways)
		case .disabled:
			self.showDisabledAlert(.locationInUse)
		default:
			break
		}
	}

	/**
	Returns the current permission status for accessing LocationAlways.

	- returns: Permission status for the requested type.
	*/
	public func statusLocationAlways() -> PermissionStatus {
		guard CLLocationManager.locationServicesEnabled() else { return .disabled }

		let status = CLLocationManager.authorizationStatus()
		switch status {
		case .authorizedAlways:
			return .authorized
		case .restricted, .denied:
			return .unauthorized
		case .authorizedWhenInUse:
			// Curious why this happens? Details on upgrading from WhenInUse to Always:
			// [Check this issue](https://github.com/nickoneill/PermissionScope/issues/24)
			if defaults.bool(forKey: Constants.NSUserDefaultsKeys.requestedInUseToAlwaysUpgrade) {
				return .unauthorized
			} else {
				return .unknown
			}
		case .notDetermined:
			return .unknown
		}
	}

}
