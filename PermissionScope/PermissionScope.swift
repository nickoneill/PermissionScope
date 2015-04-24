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
import AVFoundation
import Photos

public enum PermissionType: String {
    case Contacts = "Contacts"
    case LocationAlways = "LocationAlways"
    case LocationInUse = "LocationInUse"
    case Notifications = "Notifications"
    case Microphone = "Microphone"
    case Camera = "Camera"
    case Photos = "Photos"
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

extension UIColor {
    var inverseColor: UIColor{
        var r:CGFloat = 0.0; var g:CGFloat = 0.0; var b:CGFloat = 0.0; var a:CGFloat = 0.0;
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return UIColor(red: 1.0-r, green: 1.0 - g, blue: 1.0 - b, alpha: a)
        }
        return self
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

    // Computed variables
    var allAuthorized: Bool {
        let permissionsArray = getResultsForConfig()
        return permissionsArray.filter { $0.status != .Authorized }.isEmpty
    }
    
    var requiredAuthorized: Bool {
        let permissionsArray = getResultsForConfig()
        return permissionsArray.filter { $0.status != .Authorized && $0.demands == .Required }.isEmpty
    }
    
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
            
            // TODO: New func to setUnauthorizedStyle ? new tintColor also ?
            // Question: Use (XXX, YYY) tuple instead of case XXX: if status() = YYY ? => Each Permission should know how to get it's status
            let type = configuredPermissions[index].type
            switch type {
            case .LocationAlways:
                if statusLocationAlways() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Got Location".uppercaseString, forState: UIControlState.Normal)
                } else if statusNotifications() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied Location".uppercaseString, forState: UIControlState.Normal)
                }
            case .LocationInUse:
                if statusLocationInUse() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Got Location".uppercaseString, forState: UIControlState.Normal)
                } else if statusLocationInUse() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied Location".uppercaseString, forState: UIControlState.Normal)
                }
            case .Contacts:
                if statusContacts() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed Contacts".uppercaseString, forState: UIControlState.Normal)
                } else if statusContacts() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                }
            case .Notifications:
                if statusNotifications() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed Notifications".uppercaseString, forState: UIControlState.Normal)
                } else if statusNotifications() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                }
            case .Microphone:
                if statusMicrophone() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                } else if statusMicrophone() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                }
            case .Camera:
                if statusCamera() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                } else if statusCamera() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                }
            case .Photos:
                if statusPhotos() == .Authorized {
                    setButtonAuthorizedStyle(button)
                    button.setTitle("Allowed \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
                } else if statusPhotos() == .Unauthorized {
                    setButtonUnauthorizedStyle(button)
                    button.setTitle("Denied \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
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
        case .LocationAlways, .LocationInUse:
            button.setTitle("Enable Location".uppercaseString, forState: UIControlState.Normal)
        default:
            button.setTitle("Allow \(type.rawValue)".uppercaseString, forState: UIControlState.Normal)
        }
        
        button.addTarget(self, action: Selector("request\(type.rawValue)"), forControlEvents: UIControlEvents.TouchUpInside)
        
        return button
    }

    func setButtonAuthorizedStyle(button: UIButton) {
        button.layer.borderWidth = 0
        button.backgroundColor = tintColor
        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }
    
    func setButtonUnauthorizedStyle(button: UIButton) {
        // TODO: Complete
        button.layer.borderWidth = 0
        button.backgroundColor = tintColor.inverseColor
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
        switch status {
        case .AuthorizedAlways:
            return .Authorized
        case .Restricted, .Denied, .AuthorizedWhenInUse:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }

    func requestLocationAlways() {
        if statusLocationAlways() != .Authorized {
            locationManager.delegate = self
            locationManager.requestAlwaysAuthorization()
        } else if statusContacts() == .Unauthorized {
            self.showDeniedAlert(.LocationAlways)
        }
    }

    public func statusLocationInUse() -> PermissionStatus {
        let status = CLLocationManager.authorizationStatus()
        // if you're already "always" authorized, then you don't need in use
        // but the user can still demote you! So I still use them separately.
        switch status {
        case .AuthorizedWhenInUse, .AuthorizedAlways:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }

    func requestLocationInUse() {
        if statusLocationInUse() != .Authorized {
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        } else if statusContacts() == .Unauthorized {
            self.showDeniedAlert(.LocationInUse)
        }
    }

    public func statusContacts() -> PermissionStatus {
        let status = ABAddressBookGetAuthorizationStatus()
        switch status {
            case .Authorized:
                return .Authorized
            case .Restricted, .Denied:
                return .Unauthorized
            case .NotDetermined:
                return .Unknown
        }
    }

    func requestContacts() {
        if statusContacts() == .Unknown {
            ABAddressBookRequestAccessWithCompletion(nil) { (success, error) -> Void in
                self.detectAndCallback()
            }
        } else if statusContacts() == .Unauthorized {
            self.showDeniedAlert(.Contacts)
        }
    }

    public func statusNotifications() -> PermissionStatus {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if settings.types != UIUserNotificationType.None {
            return .Authorized
        } else {
            return .Unauthorized
        }
        
        //        return .Unknown
    }
    
    func requestNotifications() {
        if statusNotifications() != .Authorized {
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge, categories: nil))
            self.pollForNotificationChanges()
        } else if statusNotifications() == .Unauthorized {
            // TODO: Alert. User must go to Settings.
            self.showDeniedAlert(.Notifications)
        }
    }
    
    public func statusMicrophone() -> PermissionStatus {
        let status = AVAudioSession.sharedInstance().recordPermission()
        if status == .Granted {
            return .Authorized
        } else if status == .Denied {
            return .Unauthorized
        }
        
        return .Unknown
    }
    
    func requestMicrophone() {
        if statusMicrophone() == .Unknown {
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) -> Void in
                self.detectAndCallback()
            })
        } else if statusMicrophone() == .Unauthorized {
            // TODO: Alert. User must go to Settings.
            self.showDeniedAlert(.Microphone)
        }
    }
    
    public func statusCamera() -> PermissionStatus {
        let status = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
        switch status {
        case .Authorized:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }
    
    func requestCamera() {
        if statusCamera() == .Unknown {
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
                completionHandler: { (granted) -> Void in
                    self.detectAndCallback()
            })
        } else if statusCamera() == .Unauthorized {
            // TODO: Alert. User must go to Settings.
            self.showDeniedAlert(.Camera)
        }
    }

    public func statusPhotos() -> PermissionStatus {
        let status = PHPhotoLibrary.authorizationStatus()
        switch status {
        case .Authorized:
            return .Authorized
        case .Denied, .Restricted:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }
    
    func requestPhotos() {
        if statusPhotos() == .Unknown {
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                self.detectAndCallback()
            })
        } else if statusPhotos() == .Unauthorized {
            self.showDeniedAlert(.Photos)
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
            case .Microphone:
                status = statusMicrophone();
            case .Camera:
                status = statusCamera()
            case .Photos:
                status = statusPhotos()
            }

            let result = PermissionResult(type: config.type, status: status, demands: config.demands)
            results.append(result)
        }

        return results
    }

    func showDeniedAlert(permission: PermissionType) {
        var alert = UIAlertController(title: "Permission for \(permission.rawValue) was denied.",
            message: "Go to Settings and enable access to \(permission.rawValue)",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "No",
            style: .Destructive,
            handler: nil))
        alert.addAction(UIAlertAction(title: "Ok",
            style: .Default,
            handler: { (action) -> Void in
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                UIApplication.sharedApplication().openURL(settingsUrl!)
        }))
        self.presentViewController(alert,
            animated: true, completion: nil)
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
