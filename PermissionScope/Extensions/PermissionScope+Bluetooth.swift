//
//  PermissionScope+Bluetooth.swift
//  PermissionScope
//
//  Created by Timothy Costa on 1/11/17.
//  Copyright © 2017 That Thing in Swift. All rights reserved.
//

import Foundation
import CoreBluetooth

private var bluetoothManagerKey: UInt8 = 0

@objc public class BluetoothPermission: NSObject, Permission {
	public let type: PermissionType = .bluetooth
}

extension PermissionScope: CBPeripheralManagerDelegate {
	var bluetoothManager:CBPeripheralManager {
		get {
			if let man = objc_getAssociatedObject(self, &bluetoothManagerKey) as? CBPeripheralManager {
				return man
			}
			let man = CBPeripheralManager(delegate: self, queue: nil, options:[CBPeripheralManagerOptionShowPowerAlertKey: false])
			man.delegate = self
			objc_setAssociatedObject(self, &bluetoothManagerKey, man, .OBJC_ASSOCIATION_RETAIN)
			return man
		}
	}

	/**
	Requests access to Bluetooth, if necessary.
	*/
	public func requestBluetooth() {
		let status = statusBluetooth()
		switch status {
		case .disabled:
			showDisabledAlert(.bluetooth)
		case .unauthorized:
			showDeniedAlert(.bluetooth)
		case .unknown:
			triggerBluetoothStatusUpdate()
		default:
			break
		}
		
	}

	/**
	Returns the current permission status for accessing Bluetooth.

	- returns: Permission status for the requested type.
	*/
	public func statusBluetooth() -> PermissionStatus {
		// if already asked for bluetooth before, do a request to get status, else wait for user to request
		if askedBluetooth{
			triggerBluetoothStatusUpdate()
		} else {
			return .unknown
		}

		let state = (bluetoothManager.state, CBPeripheralManager.authorizationStatus())
		switch state {
		case (.unsupported, _), (.poweredOff, _), (_, .restricted):
			return .disabled
		case (.unauthorized, _), (_, .denied):
			return .unauthorized
		case (.poweredOn, .authorized):
			return .authorized
		default:
			return .unknown
		}
	}

	func triggerBluetoothStatusUpdate() {
			if !waitingForBluetooth && bluetoothManager.state == .unknown {
			bluetoothManager.startAdvertising(nil)
			bluetoothManager.stopAdvertising()
			askedBluetooth = true
			waitingForBluetooth = true
		}
	}

	public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		waitingForBluetooth = false
		detectAndCallback()
	}

}
