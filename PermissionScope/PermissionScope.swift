//
//  PermissionScope.swift
//  PermissionScope
//
//  Created by Nick O'Neill on 4/5/15.
//  Copyright (c) 2015 That Thing in Swift. All rights reserved.
//

import UIKit
import CoreLocation
import AddressBook
//    case Microphone
//    case Camera
import AVFoundation

public enum PermissionType: String {
    case Contacts = "Contacts"
    case LocationAlways = "LocationAlways"
    case LocationInUse = "LocationInUse"
    case Notifications = "Notifications"
}

public enum PermissionStatus: String {
    case Authorized = "Authorized"
    case Unauthorized = "Unauthorized"
    case Unknown = "Unknown"
}

public enum PermissionDemands: String {
    case Required = "Required"
    case Optional = "Optional"
}

public struct PermissionConfig {
    let type: PermissionType
    let demands: PermissionDemands
    let message: String

    public init(type: PermissionType, demands: PermissionDemands, message: String) {
        self.type = type
        self.demands = demands
        self.message = message
    }
}

public struct PermissionResult: Printable {
    public let type: PermissionType
    public let status: PermissionStatus
    public let demands: PermissionDemands

    public var description: String {
        return "\(type.rawValue) \(status.rawValue)"
    }
}
    }
}

public class PermissionScope: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    // constants
    let ContentWidth: CGFloat = 280.0
    let ContentHeight: CGFloat = 480.0

    // configurable things
    public let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    public let bodyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 70))
    public var tintColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    public var buttonFont = UIFont.boldSystemFontOfSize(14)
    public var labelFont = UIFont.systemFontOfSize(14)
    public var finalizeFont = UIFont.systemFontOfSize(16)

    // some view hierarchy
    let baseView = UIView()
    let contentView = UIView()
    let finalizeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 200, height: 30))

    // various managers
    let locationManager = CLLocationManager()

    // internal state and resolution
    var configuredPermissions: [PermissionConfig] = []
    var permissionButtons: [UIButton] = []
    var permissionLabels: [UILabel] = []
    var authChangeClosure: ((Bool, [PermissionResult]) -> Void)? = nil
    var cancelClosure: (([PermissionResult]) -> Void)? = nil

    public init() {
        super.init(nibName: nil, bundle: nil)

        // Set up main view
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.7)
        view.addSubview(baseView)
        // Base View
        baseView.frame = view.frame
        baseView.addSubview(contentView)
        let tap = UITapGestureRecognizer(target: self, action: Selector("cancel"))
        tap.delegate = self
        baseView.addGestureRecognizer(tap)
        // Content View
        contentView.backgroundColor = UIColor.whiteColor()
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5

        // header label
        headerLabel.font = UIFont.systemFontOfSize(22)
        headerLabel.textColor = UIColor.blackColor()
        headerLabel.textAlignment = NSTextAlignment.Center
        headerLabel.text = "Hey, listen!"
//        headerLabel.backgroundColor = UIColor.redColor()

        contentView.addSubview(headerLabel)

        // body label
        bodyLabel.font = UIFont.boldSystemFontOfSize(16)
        bodyLabel.textColor = UIColor.blackColor()
        bodyLabel.textAlignment = NSTextAlignment.Center
        bodyLabel.text = "We need a couple things\r\nbefore you get started."
        bodyLabel.numberOfLines = 2
//        bodyLabel.text = "We need\r\na couple things before you\r\nget started."
//        bodyLabel.backgroundColor = UIColor.redColor()

        contentView.addSubview(bodyLabel)

        finalizeButton.setTitle("Let's go!", forState: UIControlState.Normal)
        finalizeButton.setTitleColor(UIColor.grayColor(), forState: UIControlState.Disabled)
        finalizeButton.enabled = false
        finalizeButton.addTarget(self, action: Selector("finish"), forControlEvents: UIControlEvents.TouchUpInside)

        contentView.addSubview(finalizeButton)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var screenSize = UIScreen.mainScreen().bounds.size
        // Set background frame
        view.frame.size = screenSize
        // Set frames
        var x = (screenSize.width - ContentWidth) / 2
        var y = (screenSize.height - ContentHeight) / 2
        contentView.frame = CGRect(x:x, y:y, width:ContentWidth, height:ContentHeight)

        // offset the header from the content center, compensate for the content's offset
        headerLabel.center = contentView.center
        headerLabel.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        headerLabel.frame.offset(dx: 0, dy: -200)

        // ... same with the body
        bodyLabel.center = contentView.center
        bodyLabel.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        bodyLabel.frame.offset(dx: 0, dy: -150)

        finalizeButton.center = contentView.center
        finalizeButton.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        finalizeButton.frame.offset(dx: 0, dy: 210)
        finalizeButton.setTitleColor(tintColor, forState: UIControlState.Normal)

        let baseOffset = 95
        var index = 0
        for button in permissionButtons {
            button.center = contentView.center
            button.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            button.frame.offset(dx: 0, dy: -80 + CGFloat(index * baseOffset))

            let type = configuredPermissions[index].type
            switch type {
            case .LocationAlways:
                if statusLocationAlways() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Got Location".uppercaseString, forState: UIControlState.Normal)
                }
            case .LocationInUse:
                if statusLocationInUse() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Got Location".uppercaseString, forState: UIControlState.Normal)
                }
            case .Contacts:
                if statusContacts() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed Contacts".uppercaseString, forState: UIControlState.Normal)
                }
            case .Notifications:
                if statusNotifications() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed Notifications".uppercaseString, forState: UIControlState.Normal)
                }
            }

            let label = permissionLabels[index]
            label.center = contentView.center
            label.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            label.frame.offset(dx: 0, dy: -35 + CGFloat(index * baseOffset))

            index++
        }
    }

    // MARK: customizing the permissions

    public func addPermission(config: PermissionConfig) {
        assert(!config.message.isEmpty, "Including a message about your permission usage is helpful")
        assert(configuredPermissions.count < 3, "Ask for three or fewer permissions at a time")

        configuredPermissions.append(config)
    }

    func permissionStyledButton(type: PermissionType) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: 40))
        button.setTitleColor(tintColor, forState: UIControlState.Normal)
        button.titleLabel?.font = buttonFont

        button.layer.borderWidth = 1
        button.layer.borderColor = tintColor.CGColor
        button.layer.cornerRadius = 6

        // this is a bit of a mess, eh?
        switch type {
        case .Contacts:
            button.setTitle("Allow Contacts".uppercaseString, forState: UIControlState.Normal)
            button.addTarget(self, action: Selector("requestContacts"), forControlEvents: UIControlEvents.TouchUpInside)
        case .LocationAlways:
            button.setTitle("Enable Location".uppercaseString, forState: UIControlState.Normal)
            button.addTarget(self, action: Selector("requestLocationAlways"), forControlEvents: UIControlEvents.TouchUpInside)
        case .LocationInUse:
            button.setTitle("Enable Location".uppercaseString, forState: UIControlState.Normal)
            button.addTarget(self, action: Selector("requestLocationInUse"), forControlEvents: UIControlEvents.TouchUpInside)
        case .Notifications:
            button.setTitle("Enable Notifications".uppercaseString, forState: UIControlState.Normal)
            button.addTarget(self, action: Selector("requestNotifications"), forControlEvents: UIControlEvents.TouchUpInside)

//        case .Microphone:
//            button.setTitle("Allow Microphone".uppercaseString, forState: UIControlState.Normal)
//        case .Camera:
//            button.setTitle("Allow Camera".uppercaseString, forState: UIControlState.Normal)
        }

        return button
    }

    func setButtonAuthorizedStyle(button: UIButton) {
        button.layer.borderWidth = 0
        button.backgroundColor = tintColor
        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }

    func permissionStyledLabel(message: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 260, height: 50))
        label.font = labelFont
        label.numberOfLines = 2
        label.textAlignment = NSTextAlignment.Center

        label.text = message
//        label.backgroundColor = UIColor.greenColor()

        return label
    }

    // MARK: dealing with system permissions

    public func statusLocationAlways() -> PermissionStatus {
        let status = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.AuthorizedAlways {
            return .Authorized
        }

        return .Unknown
    }

    func requestLocationAlways() {
        if statusLocationAlways() != .Authorized {
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        }
    }

    public func statusLocationInUse() -> PermissionStatus {
        let status = CLLocationManager.authorizationStatus()
        // if you're already "always" authorized, then you don't need in use
        // but the user can still demote you! So I still use them separately.
        if status == CLAuthorizationStatus.AuthorizedWhenInUse || status == CLAuthorizationStatus.AuthorizedAlways {
            return .Authorized
        }

        return .Unknown
    }

    func requestLocationInUse() {
        if statusLocationInUse() != .Authorized {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        }
    }

    public func statusContacts() -> PermissionStatus {
        let status = ABAddressBookGetAuthorizationStatus()
        if status == ABAuthorizationStatus.Authorized {
            return .Authorized
        }

        return .Unknown
    }

    func requestContacts() {
        if statusContacts() != .Authorized {
            ABAddressBookRequestAccessWithCompletion(nil) { (success, error) -> Void in
                self.detectAndCallback()
            }
        }
    }

    public func statusNotifications() -> PermissionStatus {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if settings.types != UIUserNotificationType.None {
            return .Authorized
        }

        return .Unknown
    }

    func requestNotifications() {
        if statusNotifications() != .Authorized {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
            self.pollForNotificationChanges()
        }
    }

    func pollForNotificationChanges() {
        // yuck
        // the alternative is telling developers to call detectAndCallback() in their app delegate

        // poll every second, try for a minute
        let pollMax = 60
        var pollCount = 0
        while pollCount <= pollMax {

            let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
//            println("polling \(settings)")
            if settings.types != UIUserNotificationType.None {
                self.detectAndCallback()
                break
            } else {
                sleep(1)
            }
        }
    }

    // MARK: finally, displaying the panel

    public func show(authChange: ((finished: Bool, results: [PermissionResult]) -> Void)? = nil, cancelled: ((results: [PermissionResult]) -> Void)? = nil) {
        assert(configuredPermissions.count > 0, "Please add at least one permission")

        authChangeClosure = authChange
        cancelClosure = cancelled

        var allAuthorized = true
        var requiredAuthorized = true
        let results = getResultsForConfig()
        for result in results {
            if result.status != .Authorized {
                allAuthorized = false
                if result.demands == .Required {
                    requiredAuthorized = false
                }
            }
        }

        // no missing required perms? callback and do nothing
        if requiredAuthorized {
            if let authChangeClosure = authChangeClosure {
                authChangeClosure(true, results)
            }

            return
        }

        // add the backing views
        let window = UIApplication.sharedApplication().keyWindow!
        window.addSubview(view)
        view.frame = window.bounds
        baseView.frame = window.bounds

        for button in permissionButtons {
            button.removeFromSuperview()
        }
        permissionButtons = []

        for label in permissionLabels {
            label.removeFromSuperview()
        }
        permissionLabels = []

        // create the buttons
        for config in configuredPermissions {
            let button = permissionStyledButton(config.type)
            permissionButtons.append(button)
            contentView.addSubview(button)

            let label = permissionStyledLabel(config.message)
            permissionLabels.append(label)
            contentView.addSubview(label)
        }

        // slide in the view
        self.baseView.frame.origin.y = -400
        UIView.animateWithDuration(0.2, animations: {
            self.baseView.center.y = window.center.y + 15
            self.view.alpha = 1
        }, completion: { finished in
            UIView.animateWithDuration(0.2, animations: {
                self.baseView.center = window.center
            })
        })
    }

    public func hide() {
        let window = UIApplication.sharedApplication().keyWindow!

        UIView.animateWithDuration(0.2, animations: {
            self.baseView.frame.origin.y = window.center.y + 400
            self.view.alpha = 0
        }, completion: { finished in
            self.view.removeFromSuperview()
        })
    }

    func cancel() {
        self.hide()

        if let cancelClosure = cancelClosure {
            cancelClosure(getResultsForConfig())
        }
    }

    func finish() {
        self.hide()

        if let authChangeClosure = authChangeClosure {
            authChangeClosure(true, getResultsForConfig())
        }
    }

    func detectAndCallback() {
        var allAuthorized = true
        var requiredAuthorized = true
        let results = getResultsForConfig()
        for result in results {
            if result.status != .Authorized {
                allAuthorized = false
                if result.demands == .Required {
                    requiredAuthorized = false
                }
            }
        }

        // compile the results and pass them back if necessary
        if let authChangeClosure = authChangeClosure {
            authChangeClosure(allAuthorized, results)
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.view.setNeedsLayout()

            // enable the finalize button if we have all required perms
            if requiredAuthorized {
                self.finalizeButton.enabled = true
            } else {
                self.finalizeButton.enabled = false
            }

            // and hide if we've sucessfully got all permissions
            if allAuthorized {
                self.hide()
            }
        })
    }

    func getResultsForConfig() -> [PermissionResult] {
        var results: [PermissionResult] = []

        for config in configuredPermissions {
            var status: PermissionStatus

            switch config.type {
            case .LocationAlways:
                status = statusLocationAlways()
            case .LocationInUse:
                status = statusLocationInUse()
            case .Contacts:
                status = statusContacts()
            case .Notifications:
                status = statusNotifications()
            }

            let result = PermissionResult(type: config.type, status: status, demands: config.demands)
            results.append(result)
        }

        return results
    }

    // MARK: gesture delegate

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        // this prevents our tap gesture from firing for subviews of baseview
        if touch.view == baseView {
            return true
        }

        return false
    }

    // MARK: location delegate

    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        detectAndCallback()
    }
}
