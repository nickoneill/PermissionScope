//
//  PermissionScope+Photos.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import Photos

@objc public class PhotosPermission: NSObject, Permission {
	public let type: PermissionType = .photos
}

extension PermissionScope {
	/**
	Requests access to Photos, if necessary.
	*/
	public func requestPhotos() {
		let status = statusPhotos()
		switch status {
		case .unknown:
			PHPhotoLibrary.requestAuthorization({ status in
				self.detectAndCallback()
			})
		case .unauthorized:
			self.showDeniedAlert(.photos)
		case .disabled:
			showDisabledAlert(.photos)
		case .authorized:
			break
		}
	}

	/**
	Returns the current permission status for accessing Photos.

	- returns: Permission status for the requested type.
	*/
	public func statusPhotos() -> PermissionStatus {
		let status = PHPhotoLibrary.authorizationStatus()
		switch status {
		case .authorized:
			return .authorized
		case .denied, .restricted:
			return .unauthorized
		case .notDetermined:
			return .unknown
		}
	}


}
