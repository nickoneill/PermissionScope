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
import EventKit
import CoreBluetooth

struct PermissionScopeConstants {
    static let requestedInUseToAlwaysUpgrade = "requestedInUseToAlwaysUpgrade"
    static let requestedForBluetooth = "askedForBluetooth"
}

public enum PermissionType: String {
    case Contacts       = "Contacts"
    case LocationAlways = "LocationAlways"
    case LocationInUse  = "LocationInUse"
    case Notifications  = "Notifications"
    case Microphone     = "Microphone"
    case Camera         = "Camera"
    case Photos         = "Photos"
    case Reminders      = "Reminders"
    case Events         = "Events"
    case Bluetooth      = "Bluetooth"
    
    var prettyName: String {
        switch self {
        case .LocationAlways, .LocationInUse:
            return "Location"
        default:
            return self.rawValue
        }
    }
    
    static let allValues = [Contacts, LocationAlways, LocationInUse, Notifications, Microphone, Camera, Photos, Reminders, Events]
}

public enum PermissionStatus: String {
    case Authorized     = "Authorized"
    case Unauthorized   = "Unauthorized"
    case Unknown        = "Unknown"
    case Disabled       = "Disabled" // System-level
}

public enum PermissionDemands: String {
    case Required = "Required"
    case Optional = "Optional"
}

private let PermissionScopeAskedForNotificationsDefaultsKey = "PermissionScopeAskedForNotificationsDefaultsKey"

public struct PermissionConfig {
    let type: PermissionType
    let demands: PermissionDemands
    let message: String
    
    let notificationCategories: Set<UIUserNotificationCategory>?
    
    public init(type: PermissionType, demands: PermissionDemands, message: String, notificationCategories: Set<UIUserNotificationCategory>? = .None) {
        if type != .Notifications && notificationCategories != .None {
            assertionFailure("notificationCategories only apply to the .Notifications permission")
        }

        self.type = type
        self.demands = demands
        self.message = message
        self.notificationCategories = notificationCategories
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
extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

public class PermissionScope: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, CBPeripheralManagerDelegate {
    // constants
    let contentWidth: CGFloat = 280.0

    // configurable things
    public let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    public let bodyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 70))
    public var tintColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    public var buttonFont = UIFont.boldSystemFontOfSize(14)
    public var labelFont = UIFont.systemFontOfSize(14)
    public var closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 32))
    public var closeOffset = CGSize(width: 0, height: 0)

    // some view hierarchy
    let baseView = UIView()
    let contentView = UIView()

    // various managers
    lazy var locationManager:CLLocationManager = {
        let lm = CLLocationManager()
        lm.delegate = self
        return lm
    }()

    lazy var bluetoothManager:CBPeripheralManager = {
        return CBPeripheralManager(delegate: self, queue: nil)
    }()

    // internal state and resolution
    var configuredPermissions: [PermissionConfig] = []
    var permissionButtons: [UIButton] = []
    var permissionLabels: [UILabel] = []
	
	// properties that may be useful for direct use of the request* methods
    public var authChangeClosure: ((Bool, [PermissionResult]) -> Void)? = nil
    public var cancelClosure: (([PermissionResult]) -> Void)? = nil
	/** Called when the user has disabled or denied access to notifications, and we're presenting them with a help dialog. */
    public var disabledOrDeniedClosure: (([PermissionResult]) -> Void)? = nil
	/** View controller to be used when presenting alerts. Defaults to self. You'll want to set this if you are calling the `request*` methods directly. */
	public var viewControllerForAlerts : UIViewController?

    // Computed variables
    var allAuthorized: Bool {
        let permissionsArray = getResultsForConfig()
        return permissionsArray.filter { $0.status != .Authorized }.isEmpty
    }
    var requiredAuthorized: Bool {
        let permissionsArray = getResultsForConfig()
        return permissionsArray.filter { $0.status != .Authorized && $0.demands == .Required }.isEmpty
    }
    
    // use the code we have to see permission status
    public func permissionStatuses(permissionTypes: [PermissionType]?) -> Dictionary<PermissionType, PermissionStatus> {
        var statuses: Dictionary<PermissionType, PermissionStatus> = [:]
        var types = permissionTypes
        
        if types == nil {
            types = PermissionType.allValues
        }
        
        if let types = types {
            for type in types {
                statuses[type] = self.statusForPermission(type)
            }
        }
        
        return statuses
    }
    
    public init(backgroundTapCancels: Bool) {
        super.init(nibName: nil, bundle: nil)

		viewControllerForAlerts = self
		
        // Set up main view
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.7)
        view.addSubview(baseView)
        // Base View
        baseView.frame = view.frame
        baseView.addSubview(contentView)
        if backgroundTapCancels {
            let tap = UITapGestureRecognizer(target: self, action: Selector("cancel"))
            tap.delegate = self
            baseView.addGestureRecognizer(tap)
        }
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
        
        // close button
        closeButton.setTitle("Close", forState: UIControlState.Normal)
        closeButton.addTarget(self, action: Selector("cancel"), forControlEvents: UIControlEvents.TouchUpInside)
        
        contentView.addSubview(closeButton)
    }
    
    public convenience init() {
        self.init(backgroundTapCancels: true)
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
        var x = (screenSize.width - contentWidth) / 2

        let dialogHeight: CGFloat
        switch self.configuredPermissions.count {
        case 2:
            dialogHeight = 360
        case 3:
            dialogHeight = 460
        default:
            dialogHeight = 260
        }
        
        var y = (screenSize.height - dialogHeight) / 2
        contentView.frame = CGRect(x:x, y:y, width:contentWidth, height:dialogHeight)

        // offset the header from the content center, compensate for the content's offset
        headerLabel.center = contentView.center
        headerLabel.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        headerLabel.frame.offset(dx: 0, dy: -((dialogHeight/2)-50))

        // ... same with the body
        bodyLabel.center = contentView.center
        bodyLabel.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        bodyLabel.frame.offset(dx: 0, dy: -((dialogHeight/2)-100))
        
        closeButton.center = contentView.center
        closeButton.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        closeButton.frame.offset(dx: 105, dy: -((dialogHeight/2)-20))
        closeButton.frame.offset(dx: self.closeOffset.width, dy: self.closeOffset.height)
        if closeButton.imageView?.image != nil {
            closeButton.setTitle("", forState: UIControlState.Normal)
        }
        closeButton.setTitleColor(tintColor, forState: UIControlState.Normal)

        let baseOffset = 95
        var index = 0
        for button in permissionButtons {
            button.center = contentView.center
            button.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            button.frame.offset(dx: 0, dy: -((dialogHeight/2)-160) + CGFloat(index * baseOffset))
            
            let type = configuredPermissions[index].type
            
            let currentStatus = statusForPermission(type)
            let prettyName = type.prettyName
            if currentStatus == .Authorized {
                setButtonAuthorizedStyle(button)
                button.setTitle("Allowed \(prettyName)".localized.uppercaseString, forState: .Normal)
            } else if currentStatus == .Unauthorized {
                setButtonUnauthorizedStyle(button)
                button.setTitle("Denied \(prettyName)".localized.uppercaseString, forState: .Normal)
            } else if currentStatus == .Disabled {
//                setButtonDisabledStyle(button)
                button.setTitle("\(prettyName) Disabled".localized.uppercaseString, forState: .Normal)
            }

            let label = permissionLabels[index]
            label.center = contentView.center
            label.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            label.frame.offset(dx: 0, dy: -((dialogHeight/2)-205) + CGFloat(index * baseOffset))

            index++
        }
    }

    // MARK: customizing the permissions

    public func addPermission(config: PermissionConfig) {
        assert(!config.message.isEmpty, "Including a message about your permission usage is helpful")
        assert(configuredPermissions.count < 3, "Ask for three or fewer permissions at a time")
        assert(configuredPermissions.filter { $0.type == config.type }.isEmpty, "Permission for \(config.type.rawValue) already set")
        
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
            button.setTitle("Enable \(type.prettyName)".localized.uppercaseString, forState: UIControlState.Normal)
        default:
            button.setTitle("Allow \(type.rawValue)".localized.uppercaseString, forState: UIControlState.Normal)
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

    // MARK: status and requests for each permission

    public func statusLocationAlways() -> PermissionStatus {
        if !CLLocationManager.locationServicesEnabled() {
            return .Disabled
        }

        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .AuthorizedAlways:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .AuthorizedWhenInUse:
            let defaults = NSUserDefaults.standardUserDefaults()
            // curious why this happens? Details on upgrading from WhenInUse to Always:
            // https://github.com/nickoneill/PermissionScope/issues/24
            if defaults.boolForKey(PermissionScopeConstants.requestedInUseToAlwaysUpgrade) == true {
                return .Unauthorized
            } else {
                return .Unknown
            }
        case .NotDetermined:
            return .Unknown
        }
    }

    public func requestLocationAlways() {
        switch statusLocationAlways() {
        case .Unknown:
            if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
                let defaults = NSUserDefaults.standardUserDefaults()
                defaults.setBool(true, forKey: PermissionScopeConstants.requestedInUseToAlwaysUpgrade)
                defaults.synchronize()
            }
            locationManager.requestAlwaysAuthorization()
        case .Unauthorized:
            self.showDeniedAlert(.LocationAlways)
        case .Disabled:
            self.showDisabledAlert(.LocationInUse)
        default:
            break
        }
    }

    public func statusLocationInUse() -> PermissionStatus {
        if !CLLocationManager.locationServicesEnabled() {
            return .Disabled
        }
        
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

    public func requestLocationInUse() {
        switch statusLocationInUse() {
        case .Unknown:
            locationManager.requestWhenInUseAuthorization()
        case .Unauthorized:
            self.showDeniedAlert(.LocationInUse)
        case .Disabled:
            self.showDisabledAlert(.LocationInUse)
        default:
            break
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

    public func requestContacts() {
        switch statusContacts() {
        case .Unknown:
            ABAddressBookRequestAccessWithCompletion(nil) { (success, error) -> Void in
                self.detectAndCallback()
            }
        case .Unauthorized:
            self.showDeniedAlert(.Contacts)
        default:
            break
        }
    }

    // TODO: can we tell if notifications has been denied?
    public func statusNotifications() -> PermissionStatus {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if settings.types != UIUserNotificationType.None {
            return .Authorized
        } else {
            if NSUserDefaults.standardUserDefaults().boolForKey(PermissionScopeAskedForNotificationsDefaultsKey) {
                return .Unauthorized
            } else {
                return .Unknown
            }
        }
    }
    
    func showingNotificationPermission () {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("finishedShowingNotificationPermission"), name: UIApplicationDidBecomeActiveNotification, object: nil)
        notificationTimer?.invalidate()
    }
    
    var notificationTimer : NSTimer?

    func finishedShowingNotificationPermission () {
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillResignActiveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        notificationTimer?.invalidate()
        
        let allResults = getResultsForConfig().filter {
            $0.type == PermissionType.Notifications
        }
        if let notificationResult : PermissionResult = allResults.first {
            if notificationResult.status == PermissionStatus.Unknown {
                showDeniedAlert(notificationResult.type)
            } else {
                detectAndCallback()
            }
        }
        
    }
    
    public func requestNotifications() {
        switch statusNotifications() {
        case .Unknown:
            
            // There should be only one...
            let notificationsPermissionSet = self.configuredPermissions.filter { $0.notificationCategories != .None && !$0.notificationCategories!.isEmpty }.first?.notificationCategories
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: PermissionScopeAskedForNotificationsDefaultsKey)
            NSUserDefaults.standardUserDefaults().synchronize()
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showingNotificationPermission"), name: UIApplicationWillResignActiveNotification, object: nil)
            
            notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("finishedShowingNotificationPermission"), userInfo: nil, repeats: false)

            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: .Alert | .Sound | .Badge,
                categories: notificationsPermissionSet))
            
        case .Unauthorized:
            
            showDeniedAlert(PermissionType.Notifications)
            
        default:
            break
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
    
    public func requestMicrophone() {
        switch statusMicrophone() {
        case .Unknown:
            AVAudioSession.sharedInstance().requestRecordPermission({ (granted) -> Void in
                self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Microphone)
        default:
            break
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
    
    public func requestCamera() {
        switch statusCamera() {
        case .Unknown:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
                completionHandler: { (granted) -> Void in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Camera)
        default:
            break
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
    
    public func requestPhotos() {
        switch statusPhotos() {
        case .Unknown:
            PHPhotoLibrary.requestAuthorization({ (status) -> Void in
                self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Photos)
        default:
            break
        }
    }
    
    public func statusReminders() -> PermissionStatus {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityTypeReminder)
        switch status {
        case .Authorized:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }
    
    public func requestReminders() {
        switch statusReminders() {
        case .Unknown:
            EKEventStore().requestAccessToEntityType(EKEntityTypeReminder,
                completion: { (granted, error) -> Void in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Reminders)
        default:
            break
        }
    }
    
    public func statusEvents() -> PermissionStatus {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityTypeEvent)
        switch status {
        case .Authorized:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }
    
    public func requestEvents() {
        switch statusEvents() {
        case .Unknown:
            EKEventStore().requestAccessToEntityType(EKEntityTypeEvent,
                completion: { (granted, error) -> Void in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Events)
        default:
            break
        }
    }
    
    
    public func statusBluetooth() -> PermissionStatus{
        let askedBluetooth = NSUserDefaults.standardUserDefaults().boolForKey(PermissionScopeConstants.requestedForBluetooth)
        
        // if already asked for bluetooth before, do a request to get status, else wait for user to request
        if askedBluetooth{
            triggerBluetoothStatusUpdate()
        } else {
            return .Unknown
        }

        switch (bluetoothManager.state, CBPeripheralManager.authorizationStatus()) {
        
        case (.Unsupported, _), (.PoweredOff, _), (_, .Restricted):
            return .Disabled
        case (.Unauthorized, _), (_, .Denied):
            return .Unauthorized
        case (.PoweredOn, .Authorized):
            return .Authorized
        default:
            return .Unknown
        }
        
    }
    
    func requestBluetooth() {
        
        switch statusBluetooth() {
        case .Disabled:
            showDisabledAlert(.Bluetooth)
        case .Unauthorized:
            showDeniedAlert(.Bluetooth)
        case .Unknown:
            triggerBluetoothStatusUpdate()
        default:
            break
        }
        
    }
    
    private func triggerBluetoothStatusUpdate() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: PermissionScopeConstants.requestedForBluetooth)
        NSUserDefaults.standardUserDefaults().synchronize()
        bluetoothManager.startAdvertising(nil)
        bluetoothManager.stopAdvertising()
    }
    
    // MARK: finally, displaying the panel

    public func show(authChange: ((finished: Bool, results: [PermissionResult]) -> Void)? = nil, cancelled: ((results: [PermissionResult]) -> Void)? = nil) {
        assert(configuredPermissions.count > 0, "Please add at least one permission")

        authChangeClosure = authChange
        cancelClosure = cancelled

        // no missing required perms? callback and do nothing
        if requiredAuthorized {
            if let authChangeClosure = authChangeClosure {
                authChangeClosure(true, getResultsForConfig())
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
        
        self.view.setNeedsLayout()
        
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
        
        notificationTimer?.invalidate()
        notificationTimer = nil
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
        // compile the results and pass them back if necessary
        if let authChangeClosure = authChangeClosure {
            authChangeClosure(allAuthorized, getResultsForConfig())
        }

        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.view.setNeedsLayout()

            // and hide if we've sucessfully got all permissions
            if self.allAuthorized {
                self.hide()
            }
        })
    }

    func getResultsForConfig() -> [PermissionResult] {
        var results: [PermissionResult] = []

        for config in configuredPermissions {
            var status = statusForPermission(config.type)
            let result = PermissionResult(type: config.type, status: status, demands: config.demands)
            results.append(result)
        }

        return results
    }

    func appForegroundedAfterSettings (){

        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        detectAndCallback()
    }
    
    func showDeniedAlert(permission: PermissionType) {
        if let disabledOrDeniedClosure = self.disabledOrDeniedClosure {
            disabledOrDeniedClosure(self.getResultsForConfig())
        }
        var alert = UIAlertController(title: "Permission for \(permission.rawValue) was denied.",
            message: "Please enable access to \(permission.rawValue) in the Settings app",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: .Cancel,
            handler: nil))
        alert.addAction(UIAlertAction(title: "Show me",
            style: .Default,
            handler: { (action) -> Void in
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appForegroundedAfterSettings"), name: UIApplicationDidBecomeActiveNotification, object: nil)
                
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                UIApplication.sharedApplication().openURL(settingsUrl!)
        }))
        viewControllerForAlerts?.presentViewController(alert,
            animated: true, completion: nil)
    }
    
    func showDisabledAlert(permission: PermissionType) {
        if let disabledOrDeniedClosure = self.disabledOrDeniedClosure {
            disabledOrDeniedClosure(self.getResultsForConfig())
        }
        var alert = UIAlertController(title: "\(permission.rawValue) is currently disabled.",
            message: "Please enable access to \(permission.rawValue) in Settings",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: .Cancel,
            handler: nil))
        viewControllerForAlerts?.presentViewController(alert,
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
    
    // MARK: bluetooth delegate
    
    public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager!) {
        
        detectAndCallback()
    }

    // MARK: Helpers
    
    func statusForPermission(type: PermissionType) -> PermissionStatus {
        // :(
        switch type {
        case .LocationAlways:
            return statusLocationAlways()
        case .LocationInUse:
            return statusLocationInUse()
        case .Contacts:
            return statusContacts()
        case .Notifications:
            return statusNotifications()
        case .Microphone:
            return statusMicrophone()
        case .Camera:
            return statusCamera()
        case .Photos:
            return statusPhotos()
        case .Reminders:
            return statusReminders()
        case .Events:
            return statusEvents()
        case .Bluetooth:
            return statusBluetooth()
        }
    }
}