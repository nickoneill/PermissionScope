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
import CoreMotion
import HealthKit

public typealias statusRequestClosure = (status: PermissionStatus) -> Void
public typealias authClosureType      = (finished: Bool, results: [PermissionResult]) -> Void
public typealias cancelClosureType    = (results: [PermissionResult]) -> Void
typealias resultsForConfigClosure     = ([PermissionResult]) -> Void

@objc public class PermissionScope: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, CBPeripheralManagerDelegate {

    // MARK: UI Parameters
    
    /// Header UILabel with the message "Hey, listen!" by default.
    public let headerLabel                 = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    /// Header UILabel with the message "We need a couple things\r\nbefore you get started." by default.
    public let bodyLabel                   = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 70))
    /// Color for the close button's text color.
    public var closeButtonTextColor        = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    /// Color for the permission buttons' text color.
    public var permissionButtonTextColor   = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    /// Color for the permission buttons' border color.
    public var permissionButtonBorderColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    /// Width for the permission buttons.
    public var permissionButtonΒorderWidth  : CGFloat = 1
    /// Corner radius for the permission buttons.
    public var permissionButtonCornerRadius : CGFloat = 6
    /// Color for the permission labels' text color.
    public var permissionLabelColor:UIColor = .blackColor()
    /// Font used for all the UIButtons
    public var buttonFont:UIFont            = .boldSystemFontOfSize(14)
    /// Font used for all the UILabels
    public var labelFont:UIFont             = .systemFontOfSize(14)
    /// Close button. By default in the top right corner.
    public var closeButton                  = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 32))
    /// Offset used to position the Close button.
    public var closeOffset                  = CGSizeZero
    /// Color used for permission buttons with authorized status
    public var authorizedButtonColor        = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    /// Color used for permission buttons with unauthorized status. By default, inverse of `authorizedButtonColor`.
    public var unauthorizedButtonColor:UIColor?
    /// Messages for the body label of the dialog presented when requesting access.
    lazy var permissionMessages: [PermissionType : String] = [PermissionType : String]()
    
    // MARK: View hierarchy for custom alert
    let baseView    = UIView()
    public let contentView = UIView()

    // MARK: - Various lazy managers
    lazy var locationManager:CLLocationManager = {
        let lm = CLLocationManager()
        lm.delegate = self
        return lm
    }()

    lazy var bluetoothManager:CBPeripheralManager = {
        return CBPeripheralManager(delegate: self, queue: nil, options:[CBPeripheralManagerOptionShowPowerAlertKey: true])
    }()
    
    lazy var motionManager:CMMotionActivityManager = {
        return CMMotionActivityManager()
    }()
    
    /// NSUserDefaults standardDefaults lazy var
    lazy var defaults:NSUserDefaults = {
        return .standardUserDefaults()
    }()
    
    /// Default status for Core Motion Activity
    var motionPermissionStatus: PermissionStatus = .Unknown

    // MARK: - Internal state and resolution
    
    /// Permissions configured using `addPermission(:)`
    var configuredPermissions: [Permission] = []
    var permissionButtons: [UIButton]       = []
    var permissionLabels: [UILabel]         = []
	
	// Useful for direct use of the request* methods
    
    /// Callback called when permissions status change.
    public var onAuthChange: authClosureType? = nil
    /// Callback called when the user taps on the close button.
    public var onCancel: cancelClosureType?   = nil
    
    /// Called when the user has disabled or denied access to notifications, and we're presenting them with a help dialog.
    public var onDisabledOrDenied: cancelClosureType? = nil
	/// View controller to be used when presenting alerts. Defaults to self. You'll want to set this if you are calling the `request*` methods directly.
	public var viewControllerForAlerts : UIViewController?

    /**
    Checks whether all the configured permission are authorized or not.
    
    - parameter completion: Closure used to send the result of the check.
    */
    func allAuthorized(completion: (Bool) -> Void ) {
        getResultsForConfig{ results in
            let result = results
                .first { $0.status != .Authorized }
                .isNil
            completion(result)
        }
    }
    
    /**
    Checks whether all the required configured permission are authorized or not.
    **Deprecated** See issues #50 and #51.
    
    - parameter completion: Closure used to send the result of the check.
    */
    func requiredAuthorized(completion: (Bool) -> Void ) {
        getResultsForConfig{ results in
            let result = results
                .first { $0.status != .Authorized }
                .isNil
            completion(result)
        }
    }
    
    // use the code we have to see permission status
    public func permissionStatuses(permissionTypes: [PermissionType]?) -> Dictionary<PermissionType, PermissionStatus> {
        var statuses: Dictionary<PermissionType, PermissionStatus> = [:]
        let types: [PermissionType] = permissionTypes ?? PermissionType.allValues
        
        for type in types {
            statusForPermission(type, completion: { status in
                statuses[type] = status
            })
        }
        
        return statuses
    }
    
    /**
    Designated initializer.
    
    - parameter backgroundTapCancels: True if a tap on the background should trigger the dialog dismissal.
    */
    public init(backgroundTapCancels: Bool) {
        super.init(nibName: nil, bundle: nil)

		viewControllerForAlerts = self
		
        // Set up main view
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = [UIViewAutoresizing.FlexibleHeight, UIViewAutoresizing.FlexibleWidth]
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

        contentView.addSubview(headerLabel)

        // body label
        bodyLabel.font = UIFont.boldSystemFontOfSize(16)
        bodyLabel.textColor = UIColor.blackColor()
        bodyLabel.textAlignment = NSTextAlignment.Center
        bodyLabel.text = "We need a couple things\r\nbefore you get started."
        bodyLabel.numberOfLines = 2

        contentView.addSubview(bodyLabel)
        
        // close button
        closeButton.setTitle("Close", forState: .Normal)
        closeButton.addTarget(self, action: Selector("cancel"), forControlEvents: UIControlEvents.TouchUpInside)
        
        contentView.addSubview(closeButton)
        
        self.statusMotion() //Added to check motion status on load
    }
    
    /**
    Convenience initializer. Same as `init(backgroundTapCancels: true)`
    */
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
        let screenSize = UIScreen.mainScreen().bounds.size
        // Set background frame
        view.frame.size = screenSize
        // Set frames
        let x = (screenSize.width - Constants.UI.contentWidth) / 2

        let dialogHeight: CGFloat
        switch self.configuredPermissions.count {
        case 2:
            dialogHeight = Constants.UI.dialogHeightTwoPermissions
        case 3:
            dialogHeight = Constants.UI.dialogHeightThreePermissions
        default:
            dialogHeight = Constants.UI.dialogHeightSinglePermission
        }
        
        let y = (screenSize.height - dialogHeight) / 2
        contentView.frame = CGRect(x:x, y:y, width:Constants.UI.contentWidth, height:dialogHeight)

        // offset the header from the content center, compensate for the content's offset
        headerLabel.center = contentView.center
        headerLabel.frame.offsetInPlace(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        headerLabel.frame.offsetInPlace(dx: 0, dy: -((dialogHeight/2)-50))

        // ... same with the body
        bodyLabel.center = contentView.center
        bodyLabel.frame.offsetInPlace(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        bodyLabel.frame.offsetInPlace(dx: 0, dy: -((dialogHeight/2)-100))
        
        closeButton.center = contentView.center
        closeButton.frame.offsetInPlace(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        closeButton.frame.offsetInPlace(dx: 105, dy: -((dialogHeight/2)-20))
        closeButton.frame.offsetInPlace(dx: self.closeOffset.width, dy: self.closeOffset.height)
        if let _ = closeButton.imageView?.image {
            closeButton.setTitle("", forState: .Normal)
        }
        closeButton.setTitleColor(closeButtonTextColor, forState: .Normal)

        let baseOffset = 95
        var index = 0
        for button in permissionButtons {
            button.center = contentView.center
            button.frame.offsetInPlace(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            button.frame.offsetInPlace(dx: 0, dy: -((dialogHeight/2)-160) + CGFloat(index * baseOffset))
            
            let type = configuredPermissions[index].type
            
            statusForPermission(type,
                completion: { currentStatus in
                    let prettyDescription = type.prettyDescription
                    if currentStatus == .Authorized {
                        self.setButtonAuthorizedStyle(button)
                        button.setTitle("Allowed \(prettyDescription)".localized.uppercaseString, forState: .Normal)
                    } else if currentStatus == .Unauthorized {
                        self.setButtonUnauthorizedStyle(button)
                        button.setTitle("Denied \(prettyDescription)".localized.uppercaseString, forState: .Normal)
                    } else if currentStatus == .Disabled {
                        //                setButtonDisabledStyle(button)
                        button.setTitle("\(prettyDescription) Disabled".localized.uppercaseString, forState: .Normal)
                    }
                    
                    let label = self.permissionLabels[index]
                    label.center = self.contentView.center
                    label.frame.offsetInPlace(dx: -self.contentView.frame.origin.x, dy: -self.contentView.frame.origin.y)
                    label.frame.offsetInPlace(dx: 0, dy: -((dialogHeight/2)-205) + CGFloat(index * baseOffset))
                    
                    index++
            })
        }
    }

    // MARK: - Customizing the permissions
    
    /**
    Adds a permission configuration to PermissionScope.
    
    - parameter config: Configuration for a specific permission.
    - parameter message: Body label's text on the presented dialog when requesting access.
    */
    @objc public func addPermission(permission: Permission, message: String) {
        assert(!message.isEmpty, "Including a message about your permission usage is helpful")
        assert(configuredPermissions.count < 3, "Ask for three or fewer permissions at a time")
        assert(configuredPermissions.first { $0.type == permission.type }.isNil, "Permission for \(permission.type) already set")
        
        configuredPermissions.append(permission)
        permissionMessages[permission.type] = message
        
        if permission.type == .Bluetooth && askedBluetooth {
            triggerBluetoothStatusUpdate()
        } else if permission.type == .Motion && askedMotion {
            triggerMotionStatusUpdate()
        }
    }

    /**
    Permission button factory. Uses the custom style parameters such as `permissionButtonTextColor`, `buttonFont`, etc.
    
    - parameter type: Permission type
    
    - returns: UIButton instance with a custom style.
    */
    func permissionStyledButton(type: PermissionType) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: 40))
        button.setTitleColor(permissionButtonTextColor, forState: .Normal)
        button.titleLabel?.font = buttonFont

        button.layer.borderWidth = permissionButtonΒorderWidth
        button.layer.borderColor = permissionButtonBorderColor.CGColor
        button.layer.cornerRadius = permissionButtonCornerRadius

        // this is a bit of a mess, eh?
        switch type {
        case .LocationAlways, .LocationInUse:
            button.setTitle("Enable \(type.prettyDescription)".localized.uppercaseString, forState: .Normal)
        default:
            button.setTitle("Allow \(type)".localized.uppercaseString, forState: .Normal)
        }
        
        button.addTarget(self, action: Selector("request\(type)"), forControlEvents: .TouchUpInside)
        
        return button
    }

    /**
    Sets the style for permission buttons with authorized status.
    
    - parameter button: Permission button
    */
    func setButtonAuthorizedStyle(button: UIButton) {
        button.layer.borderWidth = 0
        button.backgroundColor = authorizedButtonColor
        button.setTitleColor(.whiteColor(), forState: .Normal)
    }
    
    /**
    Sets the style for permission buttons with unauthorized status.
    
    - parameter button: Permission button
    */
    func setButtonUnauthorizedStyle(button: UIButton) {
        button.layer.borderWidth = 0
        button.backgroundColor = unauthorizedButtonColor ?? authorizedButtonColor.inverseColor
        button.setTitleColor(.whiteColor(), forState: .Normal)
    }

    /**
    Permission label factory, located below the permission buttons.
    
    - parameter type: Permission type
    
    - returns: UILabel instance with a custom style.
    */
    func permissionStyledLabel(type: PermissionType) -> UILabel {
        let label  = UILabel(frame: CGRect(x: 0, y: 0, width: 260, height: 50))
        label.font = labelFont
        label.numberOfLines = 2
        label.textAlignment = .Center
        label.text = permissionMessages[type]
        label.textColor = permissionLabelColor
        
        return label
    }

    // MARK: - Status and Requests for each permission
    
    // MARK: Location
    
    /**
    Returns the current permission status for accessing LocationAlways.
    
    - returns: Permission status for the requested type.
    */
    public func statusLocationAlways() -> PermissionStatus {
        guard CLLocationManager.locationServicesEnabled() else { return .Disabled }

        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .AuthorizedAlways:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .AuthorizedWhenInUse:
            // Curious why this happens? Details on upgrading from WhenInUse to Always:
            // [Check this issue](https://github.com/nickoneill/PermissionScope/issues/24)
            if defaults.boolForKey(Constants.NSUserDefaultsKeys.requestedInUseToAlwaysUpgrade) {
                return .Unauthorized
            } else {
                return .Unknown
            }
        case .NotDetermined:
            return .Unknown
        }
    }

    /**
    Requests access to LocationAlways, if necessary.
    */
    public func requestLocationAlways() {
    	let hasAlwaysKey:Bool = !NSBundle.mainBundle()
    		.objectForInfoDictionaryKey(Constants.InfoPlistKeys.locationAlways).isNil
    	assert(hasAlwaysKey, Constants.InfoPlistKeys.locationAlways + " not found in Info.plist.")
    	
        switch statusLocationAlways() {
        case .Unknown:
            if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
                defaults.setBool(true, forKey: Constants.NSUserDefaultsKeys.requestedInUseToAlwaysUpgrade)
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

    /**
    Returns the current permission status for accessing LocationWhileInUse.
    
    - returns: Permission status for the requested type.
    */
    public func statusLocationInUse() -> PermissionStatus {
        guard CLLocationManager.locationServicesEnabled() else { return .Disabled }
        
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

    /**
    Requests access to LocationWhileInUse, if necessary.
    */
    public func requestLocationInUse() {
    	let hasWhenInUseKey :Bool = !NSBundle.mainBundle()
    		.objectForInfoDictionaryKey(Constants.InfoPlistKeys.locationWhenInUse).isNil
    	assert(hasWhenInUseKey, Constants.InfoPlistKeys.locationWhenInUse + " not found in Info.plist.")
    	
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

    // MARK: Contacts
    
    /**
    Returns the current permission status for accessing Contacts.
    
    - returns: Permission status for the requested type.
    */
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

    /**
    Requests access to Contacts, if necessary.
    */
    public func requestContacts() {
        switch statusContacts() {
        case .Unknown:
            ABAddressBookRequestAccessWithCompletion(nil) { success, error in
                self.detectAndCallback()
            }
        case .Unauthorized:
            self.showDeniedAlert(.Contacts)
        default:
            break
        }
    }

    // MARK: Notifications
    
    /**
    Returns the current permission status for accessing Notifications.
    
    - returns: Permission status for the requested type.
    */
    public func statusNotifications() -> PermissionStatus {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if let settingTypes = settings?.types where settingTypes != .None {
            return .Authorized
        } else {
            if defaults.boolForKey(Constants.NSUserDefaultsKeys.requestedNotifications) {
                return .Unauthorized
            } else {
                return .Unknown
            }
        }
    }
    
    /**
    To simulate the denied status for a notifications permission,
    we track when the permission has been asked for and then detect
    when the app becomes active again. If the permission is not granted
    immediately after becoming active, the user has cancelled or denied
    the request.
    
    This function is called when we want to show the notifications
    alert, kicking off the entire process.
    */
    func showingNotificationPermission() {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillResignActiveNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("finishedShowingNotificationPermission"),
            name: UIApplicationDidBecomeActiveNotification, object: nil)
        notificationTimer?.invalidate()
    }
    
    /**
    A timer that fires the event to let us know the user has asked for 
    notifications permission.
    */
    var notificationTimer : NSTimer?

    /**
    This function is triggered when the app becomes 'active' again after
    showing the notification permission dialog.
    
    See `showingNotificationPermission` for a more detailed description
    of the entire process.
    */
    func finishedShowingNotificationPermission () {
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationWillResignActiveNotification,
            object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self,
            name: UIApplicationDidBecomeActiveNotification,
            object: nil)
        
        notificationTimer?.invalidate()
        
        defaults.setBool(true, forKey: Constants.NSUserDefaultsKeys.requestedNotifications)
        defaults.synchronize()
        
        getResultsForConfig { results in
            guard let notificationResult = results
                .first({ $0.type == .Notifications }) else { return }
            
            if notificationResult.status == .Unknown {
                self.showDeniedAlert(notificationResult.type)
            } else {
                self.detectAndCallback()
            }
        }
    }
    
    /**
    Requests access to User Notifications, if necessary.
    */
    public func requestNotifications() {
        switch statusNotifications() {
        case .Unknown:
            let notificationsPermission = self.configuredPermissions
                .first { $0 is NotificationsPermission } as? NotificationsPermission
            let notificationsPermissionSet = notificationsPermission?.notificationCategories

            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showingNotificationPermission"), name: UIApplicationWillResignActiveNotification, object: nil)
            
            notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("finishedShowingNotificationPermission"), userInfo: nil, repeats: false)
            
            UIApplication.sharedApplication().registerUserNotificationSettings(
                UIUserNotificationSettings(forTypes: [.Alert, .Sound, .Badge],
                categories: notificationsPermissionSet)
            )
        case .Unauthorized:
            showDeniedAlert(.Notifications)
        case .Disabled:
            showDisabledAlert(.Notifications)
        case .Authorized:
            break
        }
    }
    
    // MARK: Microphone
    
    /**
    Returns the current permission status for accessing the Microphone.
    
    - returns: Permission status for the requested type.
    */
    public func statusMicrophone() -> PermissionStatus {
        
        switch AVAudioSession.sharedInstance().recordPermission() {
        case AVAudioSessionRecordPermission.Denied:
            return .Unauthorized
        case AVAudioSessionRecordPermission.Granted:
            return .Authorized
        default:
            return .Unknown
        }
    }
    
    /**
    Requests access to the Microphone, if necessary.
    */
    public func requestMicrophone() {
        switch statusMicrophone() {
        case .Unknown:
            AVAudioSession.sharedInstance().requestRecordPermission({ granted in
                self.detectAndCallback()
            })
        case .Unauthorized:
            showDeniedAlert(.Microphone)
        case .Disabled:
            showDisabledAlert(.Microphone)
        case .Authorized:
            break
        }
    }
    
    // MARK: Camera
    
    /**
    Returns the current permission status for accessing the Camera.
    
    - returns: Permission status for the requested type.
    */
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
    
    /**
    Requests access to the Camera, if necessary.
    */
    public func requestCamera() {
        switch statusCamera() {
        case .Unknown:
            AVCaptureDevice.requestAccessForMediaType(AVMediaTypeVideo,
                completionHandler: { granted in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            showDeniedAlert(.Camera)
        case .Disabled:
            showDisabledAlert(.Camera)
        case .Authorized:
            break
        }
    }

    // MARK: Photos
    
    /**
    Returns the current permission status for accessing Photos.
    
    - returns: Permission status for the requested type.
    */
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
    
    /**
    Requests access to Photos, if necessary.
    */
    public func requestPhotos() {
        switch statusPhotos() {
        case .Unknown:
            PHPhotoLibrary.requestAuthorization({ status in
                self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Photos)
        case .Disabled:
            showDisabledAlert(.Photos)
        case .Authorized:
            break
        }
    }
    
    // MARK: Reminders
    
    /**
    Returns the current permission status for accessing Reminders.
    
    - returns: Permission status for the requested type.
    */
    public func statusReminders() -> PermissionStatus {
        let status = EKEventStore.authorizationStatusForEntityType(.Reminder)
        switch status {
        case .Authorized:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }
    
    /**
    Requests access to Reminders, if necessary.
    */
    public func requestReminders() {
        switch statusReminders() {
        case .Unknown:
            EKEventStore().requestAccessToEntityType(.Reminder,
                completion: { granted, error in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Reminders)
        default:
            break
        }
    }
    
    // MARK: Events
    
    /**
    Returns the current permission status for accessing Events.
    
    - returns: Permission status for the requested type.
    */
    public func statusEvents() -> PermissionStatus {
        let status = EKEventStore.authorizationStatusForEntityType(.Event)
        switch status {
        case .Authorized:
            return .Authorized
        case .Restricted, .Denied:
            return .Unauthorized
        case .NotDetermined:
            return .Unknown
        }
    }
    
    /**
    Requests access to Events, if necessary.
    */
    public func requestEvents() {
        switch statusEvents() {
        case .Unknown:
            EKEventStore().requestAccessToEntityType(.Event,
                completion: { granted, error in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Events)
        default:
            break
        }
    }
    
    // MARK: Bluetooth
    
    /// Returns whether Bluetooth access was asked before or not.
    private var askedBluetooth:Bool {
        get {
            return defaults.boolForKey(Constants.NSUserDefaultsKeys.requestedBluetooth)
        }
        set {
            defaults.setBool(newValue, forKey: Constants.NSUserDefaultsKeys.requestedBluetooth)
            defaults.synchronize()
        }
    }
    
    /// Returns whether PermissionScope is waiting for the user to enable/disable bluetooth access or not.
    private var waitingForBluetooth = false
    
    /**
    Returns the current permission status for accessing Bluetooth.
    
    - returns: Permission status for the requested type.
    */
    public func statusBluetooth() -> PermissionStatus {
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
    
    /**
    Requests access to Bluetooth, if necessary.
    */
    public func requestBluetooth() {
        
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
    
    /**
    Start and immediately stop bluetooth advertising to trigger
    its permission dialog.
    */
    private func triggerBluetoothStatusUpdate() {
        if !waitingForBluetooth && bluetoothManager.state == .Unknown {
            bluetoothManager.startAdvertising(nil)
            bluetoothManager.stopAdvertising()
            askedBluetooth = true
            waitingForBluetooth = true
        }
    }
    
    // MARK: Core Motion Activity
    
    /**
    Returns the current permission status for accessing Core Motion Activity.
    
    - returns: Permission status for the requested type.
    */
    public func statusMotion() -> PermissionStatus {
        if askedMotion{
            triggerMotionStatusUpdate()
        }
        return motionPermissionStatus
    }
    
    /**
    Requests access to Core Motion Activity, if necessary.
    */
    public func requestMotion() {
        switch statusMotion() {
        case .Unauthorized:
            showDeniedAlert(.Motion)
        case .Unknown:
            triggerMotionStatusUpdate()
        default:
            break
        }
    }
    
    /**
    Prompts motionManager to request a status update. If permission is not already granted the user will be prompted with the system's permission dialog.
    */
    private func triggerMotionStatusUpdate() {
        let tmpMotionPermissionStatus = motionPermissionStatus
        defaults.setBool(true, forKey: Constants.NSUserDefaultsKeys.requestedMotion)
        defaults.synchronize()
        
        let today = NSDate()
        motionManager.queryActivityStartingFromDate(today,
            toDate: today,
            toQueue: .mainQueue()) { activities, error in
                if let error = error where error.code == Int(CMErrorMotionActivityNotAuthorized.rawValue) {
                    self.motionPermissionStatus = .Unauthorized
                } else {
                    self.motionPermissionStatus = .Authorized
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
    
    /// Returns whether Bluetooth access was asked before or not.
    private var askedMotion:Bool {
        get {
            return defaults.boolForKey(Constants.NSUserDefaultsKeys.requestedMotion)
        }
        set {
            defaults.setBool(newValue, forKey: Constants.NSUserDefaultsKeys.requestedMotion)
            defaults.synchronize()
        }
    }
    
    /// Returns whether PermissionScope is waiting for the user to enable/disable motion access or not.
    private var waitingForMotion = false
    
    // MARK: HealthKit
    
    /**
    Returns the current permission status for accessing HealthKit.
    
    - parameter typesToShare: HK types to share (write)
    - parameter typesToRead:  HK types to read
    
    - returns: Permission status for the requested type.
    */
    public func statusHealthKit(typesToShare: Set<HKSampleType>?, typesToRead: Set<HKObjectType>?, strict: Bool) -> PermissionStatus {
        guard HKHealthStore.isHealthDataAvailable() else { return .Disabled }
        
        var statusArray:[HKAuthorizationStatus] = []
        typesToShare?.forEach {
            statusArray.append(HKHealthStore().authorizationStatusForType($0))
        }
        typesToRead?.forEach {
            statusArray.append(HKHealthStore().authorizationStatusForType($0))
        }
        
        let typesNotDetermined = statusArray
            .filter { $0 == .NotDetermined }
        
        if typesNotDetermined.count == statusArray.count || statusArray.isEmpty {
            return .Unknown
        }
        
        let typesAuthorized = statusArray
            .first { $0 == .SharingAuthorized }
        let typesDenied = statusArray
            .first { $0 == .SharingDenied }
        
        if strict {
            if let _ = typesDenied {
                return .Unauthorized
            } else {
                return .Authorized
            }
        } else {
            if let _ = typesAuthorized {
                return .Authorized
            } else {
                return .Unauthorized
            }
        }
    }
    
    /**
    Requests access to HealthKit, if necessary.
    */
    func requestHealthKit() {
        guard let healthPermission = self.configuredPermissions
            .first({ $0.type == .HealthKit }) as? HealthPermission else { return }
        
        switch statusHealthKit(healthPermission.healthTypesToShare, typesToRead: healthPermission.healthTypesToRead, strict: healthPermission.strictMode) {
        case .Unknown:
            HKHealthStore().requestAuthorizationToShareTypes(healthPermission.healthTypesToShare,
                readTypes: healthPermission.healthTypesToRead,
                completion: { granted, error in
                    if let error = error { print("error: ", error) }
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.HealthKit)
        case .Disabled:
            self.showDisabledAlert(.HealthKit)
        case .Authorized:
            break
        }
    }
    
    // MARK: - UI
    
    /**
    Shows the modal viewcontroller for requesting access to the configured permissions and sets up the closures on it.
    
    - parameter authChange: Called when a status is detected on any of the permissions.
    - parameter cancelled:  Called when the user taps the Close button.
    */
    @objc public func show(authChange: authClosureType? = nil, cancelled: cancelClosureType? = nil) {
        assert(!configuredPermissions.isEmpty, "Please add at least one permission")

        onAuthChange = authChange
        onCancel = cancelled
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while self.waitingForBluetooth || self.waitingForMotion { }
            // call other methods that need to wait before show
            // no missing required perms? callback and do nothing
            self.requiredAuthorized({ areAuthorized in
                
                if areAuthorized {
                    self.getResultsForConfig({ results in
                        self.onAuthChange?(finished: true, results: results)
                    })
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self.showAlert()
                    }
                }
            })
        }
    }
    
    /**
    Creates the modal viewcontroller and shows it.
    */
    private func showAlert() {
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
        for permission in configuredPermissions {
            let button = permissionStyledButton(permission.type)
            permissionButtons.append(button)
            contentView.addSubview(button)

            let label = permissionStyledLabel(permission.type)
            permissionLabels.append(label)
            contentView.addSubview(label)
        }
        
        self.view.setNeedsLayout()
        
        // slide in the view
        self.baseView.frame.origin.y = self.view.bounds.origin.y - self.baseView.frame.size.height
        self.view.alpha = 0
        
        UIView.animateWithDuration(0.2, delay: 0.0, options: [], animations: {
            self.baseView.center.y = window.center.y + 15
            self.view.alpha = 1
        }, completion: { finished in
            UIView.animateWithDuration(0.2, animations: {
                self.baseView.center = window.center
            })
        })
    }

    /**
    Hides the modal viewcontroller with an animation.
    */
    public func hide() {
        let window = UIApplication.sharedApplication().keyWindow!

        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(0.2, animations: {
                self.baseView.frame.origin.y = window.center.y + 400
                self.view.alpha = 0
            }, completion: { finished in
                self.view.removeFromSuperview()
            })
        })
        
        notificationTimer?.invalidate()
        notificationTimer = nil
    }
    
    // MARK: - Delegates
    
    // MARK: Gesture delegate
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        // this prevents our tap gesture from firing for subviews of baseview
        if touch.view == baseView {
            return true
        }
        return false
    }

    // MARK: Location delegate
    
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        detectAndCallback()
    }
    
    // MARK: Bluetooth delegate
    
    public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        waitingForBluetooth = false
        detectAndCallback()
    }

    // MARK: - UI Helpers
    
    /**
    Called when the users taps on the close button.
    */
    func cancel() {
        self.hide()
        
        if let onCancel = onCancel {
            getResultsForConfig({ results in
                onCancel(results: results)
            })
        }
    }
    
    /**
    Shows an alert for a permission which was Denied.
    
    - parameter permission: Permission type.
    */
    func showDeniedAlert(permission: PermissionType) {
        let group: dispatch_group_t = dispatch_group_create()
        
        dispatch_group_async(group,
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                // compile the results and pass them back if necessary
                if let onDisabledOrDenied = self.onDisabledOrDenied {
                    self.getResultsForConfig({ results in
                        onDisabledOrDenied(results: results)
                    })
                }
        }
        
        let alert = UIAlertController(title: "Permission for \(permission) was denied.",
            message: "Please enable access to \(permission) in the Settings app",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: .Cancel,
            handler: nil))
        alert.addAction(UIAlertAction(title: "Show me",
            style: .Default,
            handler: { action in
                NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("appForegroundedAfterSettings"), name: UIApplicationDidBecomeActiveNotification, object: nil)
                
                let settingsUrl = NSURL(string: UIApplicationOpenSettingsURLString)
                UIApplication.sharedApplication().openURL(settingsUrl!)
        }))
        
        dispatch_group_notify(group,
            dispatch_get_main_queue()) {
                self.viewControllerForAlerts?.presentViewController(alert,
                    animated: true, completion: nil)
        }
    }
    
    /**
    Shows an alert for a permission which was Disabled (system-wide).
    
    - parameter permission: Permission type.
    */
    func showDisabledAlert(permission: PermissionType) {
        let group: dispatch_group_t = dispatch_group_create()
        
        dispatch_group_async(group,
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                // compile the results and pass them back if necessary
                if let onDisabledOrDenied = self.onDisabledOrDenied {
                    self.getResultsForConfig({ results in
                        onDisabledOrDenied(results: results)
                    })
                }
        }
        
        let alert = UIAlertController(title: "\(permission) is currently disabled.",
            message: "Please enable access to \(permission) in Settings",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: .Cancel,
            handler: nil))
        
        dispatch_group_notify(group,
            dispatch_get_main_queue()) {
                self.viewControllerForAlerts?.presentViewController(alert,
                    animated: true, completion: nil)
        }
    }

    // MARK: Helpers
    
    /**
    This notification callback is triggered when the app comes back
    from the settings page, after a user has tapped the "show me" 
    button to check on a disabled permission. It calls detectAndCallback
    to recheck all the permissions and update the UI.
    */
    func appForegroundedAfterSettings() {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        detectAndCallback()
    }
    
    /**
    Requests the status of any permission.
    
    - parameter type:       Permission type to be requested
    - parameter completion: Closure called when the request is done.
    */
    func statusForPermission(type: PermissionType, completion: statusRequestClosure) {
        // :(
        switch type {
        case .LocationAlways:
            completion(status: statusLocationAlways())
        case .LocationInUse:
            completion(status: statusLocationInUse())
        case .Contacts:
            completion(status: statusContacts())
        case .Notifications:
            completion(status: statusNotifications())
        case .Microphone:
            completion(status: statusMicrophone())
        case .Camera:
            completion(status: statusCamera())
        case .Photos:
            completion(status: statusPhotos())
        case .Reminders:
            completion(status: statusReminders())
        case .Events:
            completion(status: statusEvents())
        case .Bluetooth:
            completion(status: statusBluetooth())
        case .Motion:
            completion(status: statusMotion())
        case .HealthKit:
            completion(status: statusHealthKit(nil, typesToRead: nil, strict: false))
        }
    }
    
    /**
    Rechecks the status of each requested permission, updates
    the PermisisonScope UI in response and calls your onAuthChange
    to notifiy the parent app.
    */
    func detectAndCallback() {
        let group: dispatch_group_t = dispatch_group_create()
        
        dispatch_group_async(group,
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                // compile the results and pass them back if necessary
                if let onAuthChange = self.onAuthChange {
                    self.getResultsForConfig({ results in
                        self.allAuthorized({ areAuthorized in
                            onAuthChange(finished: areAuthorized, results: results)
                        })
                    })
                }
        }
        
        dispatch_group_notify(group,
            dispatch_get_main_queue()) {
                self.view.setNeedsLayout()
                
                // and hide if we've sucessfully got all permissions
                self.allAuthorized({ areAuthorized in
                    if areAuthorized {
                        self.hide()
                    }
                })
        }
    }
    
    /**
    Calculates the status for each configured permissions for the caller
    */
    func getResultsForConfig(completionBlock: resultsForConfigClosure) {
        var results: [PermissionResult] = []
        let group: dispatch_group_t = dispatch_group_create()
        
        for config in configuredPermissions {
            dispatch_group_async(group,
                dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                    self.statusForPermission(config.type, completion: { status in
                        let result = PermissionResult(type: config.type,
                            status: status)
                        results.append(result)
                    })
            }
        }
        
        dispatch_group_notify(group,
            dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                completionBlock(results)
        }
    }
}
