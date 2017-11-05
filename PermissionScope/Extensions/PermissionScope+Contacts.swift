//
//  PermissionScope+Contacts.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation

import Contacts
import AddressBook

@objc public class ContactsPermission: NSObject, Permission {
	public let type: PermissionType = .contacts
}

extension PermissionScope {
	public func requestContacts() {
		let status = statusContacts()
		switch status {
		case .unknown:
			if #available(iOS 9.0, *) {
				CNContactStore().requestAccess(for: .contacts, completionHandler: {
					success, error in
					self.detectAndCallback()
				})
			} else {
				ABAddressBookRequestAccessWithCompletion(nil) { success, error in
					self.detectAndCallback()
				}
			}
		case .unauthorized:
			self.showDeniedAlert(.contacts)
		default:
			break
		}
	}

	/**
	Returns the current permission status for accessing Contacts.

	- returns: Permission status for the requested type.
	*/
	public func statusContacts() -> PermissionStatus {
		if #available(iOS 9.0, *) {
			let status = CNContactStore.authorizationStatus(for: .contacts)
			switch status {
			case .authorized:
				return .authorized
			case .restricted, .denied:
				return .unauthorized
			case .notDetermined:
				return .unknown
			}
		} else {
			// Fallback on earlier versions
			let status = ABAddressBookGetAuthorizationStatus()
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


}
