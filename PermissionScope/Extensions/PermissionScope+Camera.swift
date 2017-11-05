//
//  PermissionScope+Camera.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import AVFoundation

@objc public class CameraPermission: NSObject, Permission {
	public let type: PermissionType = .camera
}


extension PermissionScope {
	/**
	Requests access to the Camera, if necessary.
	*/
	public func requestCamera() {
		let status = statusCamera()
		switch status {
		case .unknown:
			AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo,
			                              completionHandler: { granted in
											self.detectAndCallback()
			})
		case .unauthorized:
			showDeniedAlert(.camera)
		case .disabled:
			showDisabledAlert(.camera)
		case .authorized:
			break
		}
	}

	/**
	Returns the current permission status for accessing the Camera.

	- returns: Permission status for the requested type.
	*/
	public func statusCamera() -> PermissionStatus {
		let status = AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo)
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
