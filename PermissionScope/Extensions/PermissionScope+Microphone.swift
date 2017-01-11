//
//  PermissionScope+Microphone.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import AVFoundation

@objc public class MicrophonePermission: NSObject, Permission {
	public let type: PermissionType = .microphone
}

extension PermissionScope {
	/**
	Requests access to the Microphone, if necessary.
	*/
	public func requestMicrophone() {
		let status = statusMicrophone()
		switch status {
		case .unknown:
			AVAudioSession.sharedInstance().requestRecordPermission({ granted in
				self.detectAndCallback()
			})
		case .unauthorized:
			showDeniedAlert(.microphone)
		case .disabled:
			showDisabledAlert(.microphone)
		case .authorized:
			break
		}
	}

	/**
	Returns the current permission status for accessing the Microphone.

	- returns: Permission status for the requested type.
	*/
	public func statusMicrophone() -> PermissionStatus {
		let recordPermission = AVAudioSession.sharedInstance().recordPermission()
		switch recordPermission {
		case AVAudioSessionRecordPermission.denied:
			return .unauthorized
		case AVAudioSessionRecordPermission.granted:
			return .authorized
		default:
			return .unknown
		}
	}

}
