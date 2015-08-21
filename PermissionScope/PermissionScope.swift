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

@objc public class PermissionScope: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate, CBPeripheralManagerDelegate {
    // constants
    let contentWidth: CGFloat = 280.0

    // MARK: UI Parameters
    public let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    public let bodyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 70))
    public var tintColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)
    public var buttonFont = UIFont.boldSystemFontOfSize(14)
    public var labelFont = UIFont.systemFontOfSize(14)
    public var closeButton = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 32))
    public var closeOffset = CGSize(width: 0, height: 0)

    // MARK: View hierarchy for custom alert
    let baseView = UIView()
    let contentView = UIView()

    // various managers
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
    
    lazy var defaults:NSUserDefaults = {
        return .standardUserDefaults()
    }()
    
    // Default status for CoreMotion
    var motionPermissionStatus: PermissionStatus = .Unknown

    // Internal state and resolution
    var configuredPermissions: [PermissionConfig] = []
    var permissionButtons: [UIButton] = []
    var permissionLabels: [UILabel] = []
	
	// Useful for direct use of the request* methods
    public var authChangeClosure: authClosureType? = nil
    public typealias authClosureType = (Bool, [PermissionResult]) -> Void
    
    public var cancelClosure: cancelClosureType? = nil
	public typealias cancelClosureType = ([PermissionResult]) -> Void
    
    /** Called when the user has disabled or denied access to notifications, and we're presenting them with a help dialog. */
    public var disabledOrDeniedClosure: cancelClosureType? = nil
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
        
        self.statusMotion() //Added to check motion status on load
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
        let screenSize = UIScreen.mainScreen().bounds.size
        // Set background frame
        view.frame.size = screenSize
        // Set frames
        let x = (screenSize.width - contentWidth) / 2

        let dialogHeight: CGFloat
        switch self.configuredPermissions.count {
        case 2:
            dialogHeight = 360
        case 3:
            dialogHeight = 460
        default:
            dialogHeight = 260
        }
        
        let y = (screenSize.height - dialogHeight) / 2
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
            let prettyDescription = type.prettyDescription
            if currentStatus == .Authorized {
                setButtonAuthorizedStyle(button)
                button.setTitle("Allowed \(prettyDescription)".localized.uppercaseString, forState: .Normal)
            } else if currentStatus == .Unauthorized {
                setButtonUnauthorizedStyle(button)
                button.setTitle("Denied \(prettyDescription)".localized.uppercaseString, forState: .Normal)
            } else if currentStatus == .Disabled {
//                setButtonDisabledStyle(button)
                button.setTitle("\(prettyDescription) Disabled".localized.uppercaseString, forState: .Normal)
            }

            let label = permissionLabels[index]
            label.center = contentView.center
            label.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            label.frame.offset(dx: 0, dy: -((dialogHeight/2)-205) + CGFloat(index * baseOffset))

            index++
        }
    }

    // MARK: - Customizing the permissions

    @objc public func addPermission(config: PermissionConfig) {
        assert(!config.message.isEmpty, "Including a message about your permission usage is helpful")
        assert(configuredPermissions.count < 3, "Ask for three or fewer permissions at a time")
        assert(configuredPermissions.filter { $0.type == config.type }.isEmpty, "Permission for \(config.type.description) already set")
        
        configuredPermissions.append(config)
        
        if config.type == .Bluetooth && askedBluetooth {
            triggerBluetoothStatusUpdate()
        }
        
        if config.type == .Motion && askedMotion {
            triggerMotionStatusUpdate()
        }
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
            button.setTitle("Enable \(type.prettyDescription)".localized.uppercaseString, forState: UIControlState.Normal)
        default:
            button.setTitle("Allow \(type.description)".localized.uppercaseString, forState: UIControlState.Normal)
        }
        
        button.addTarget(self, action: Selector("request\(type.description)"), forControlEvents: UIControlEvents.TouchUpInside)
        
        return button
    }

    func setButtonAuthorizedStyle(button: UIButton) {
        button.layer.borderWidth = 0
        button.backgroundColor = tintColor
        button.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
    }
    
    func setButtonUnauthorizedStyle(button: UIButton) {
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

    // MARK: - Status and Requests for each permission
    
    // MARK: Location
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
            // curious why this happens? Details on upgrading from WhenInUse to Always:
            // https://github.com/nickoneill/PermissionScope/issues/24
            if defaults.boolForKey(Constants.requestedInUseToAlwaysUpgrade) == true {
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
                defaults.setBool(true, forKey: Constants.requestedInUseToAlwaysUpgrade)
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

    // MARK: Contacts
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

    // MARK: Notifications
    public func statusNotifications() -> PermissionStatus {
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if let settingTypes = settings?.types where settingTypes != UIUserNotificationType.None {
            return .Authorized
        } else {
            if defaults.boolForKey(Constants.askedForNotificationsDefaultsKey) {
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
            
            defaults.setBool(true, forKey: Constants.askedForNotificationsDefaultsKey)
            defaults.synchronize()
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("showingNotificationPermission"), name: UIApplicationWillResignActiveNotification, object: nil)
            
            notificationTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: Selector("finishedShowingNotificationPermission"), userInfo: nil, repeats: false)
            
            UIApplication.sharedApplication().registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, UIUserNotificationType.Sound, UIUserNotificationType.Badge],
                categories: notificationsPermissionSet))
            
        case .Unauthorized:
            
            showDeniedAlert(PermissionType.Notifications)
            
        default:
            break
        }
    }
    
    // MARK: Microphone
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
    
    // MARK: Camera
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

    // MARK: Photos
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
    
    // MARK: Reminders
    public func statusReminders() -> PermissionStatus {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Reminder)
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
            EKEventStore().requestAccessToEntityType(EKEntityType.Reminder,
                completion: { (granted, error) -> Void in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Reminders)
        default:
            break
        }
    }
    
    // MARK: Events
    public func statusEvents() -> PermissionStatus {
        let status = EKEventStore.authorizationStatusForEntityType(EKEntityType.Event)
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
            EKEventStore().requestAccessToEntityType(EKEntityType.Event,
                completion: { (granted, error) -> Void in
                    self.detectAndCallback()
            })
        case .Unauthorized:
            self.showDeniedAlert(.Events)
        default:
            break
        }
    }
    
    // MARK: Bluetooth
    private var askedBluetooth:Bool {
        get {
            return defaults.boolForKey(Constants.requestedForBluetooth)
        }
        set {
            defaults.setBool(newValue, forKey: Constants.requestedForBluetooth)
            defaults.synchronize()
        }
    }
    
    private var waitingForBluetooth = false
    
    public func statusBluetooth() -> PermissionStatus{
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
    
    private func triggerBluetoothStatusUpdate() {
        if !waitingForBluetooth && bluetoothManager.state == .Unknown {
            bluetoothManager.startAdvertising(nil)
            bluetoothManager.stopAdvertising()
            askedBluetooth = true
            waitingForBluetooth = true
        }
    }
    
    // MARK: CoreMotion
    public func statusMotion() -> PermissionStatus {
        if askedMotion{
            triggerMotionStatusUpdate()
        }
        return motionPermissionStatus
    }
    
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
    
    private func triggerMotionStatusUpdate() {
        let tmpMotionPermissionStatus = motionPermissionStatus
        defaults.setBool(true, forKey: Constants.requestedForMotion)
        defaults.synchronize()
        motionManager.queryActivityStartingFromDate(NSDate(), toDate: NSDate(), toQueue: NSOperationQueue.mainQueue(), withHandler: { (_: [CMMotionActivity]?, error:NSError?) -> Void in
            if (error != nil && error!.code == Int(CMErrorMotionActivityNotAuthorized.rawValue)) {
                self.motionPermissionStatus = .Unauthorized
                
            }
            else{
                self.motionPermissionStatus = .Authorized
            }
            
            self.motionManager.stopActivityUpdates()
            if (tmpMotionPermissionStatus != self.motionPermissionStatus){
                self.waitingForMotion = false
                self.detectAndCallback()
            }
        })
        askedMotion = true
        waitingForMotion = true
    }
    
    private var askedMotion:Bool {
        get {
            return defaults.boolForKey(Constants.requestedForMotion)
        }
        set {
            defaults.setBool(newValue, forKey: Constants.requestedForMotion)
            defaults.synchronize()
        }
    }
    
    private var waitingForMotion = false
    
    // MARK: HealthKit
    public func statusHealthKit() -> PermissionStatus {
        // There should be only one...
        // TODO: Refactor to comp. var.
        //        let healthCategoryTypes = self.configuredPermissions.filter { $0.healthCategoryTypes != .None && !$0.healthCategoryTypes!.isEmpty }.first?.healthCategoryTypes
        //        let status = HKHealthStore().authorizationStatusForType(healthCategoryType!)
        //        switch status {
        //        case .SharingAuthorized:
        //            return .Authorized
        //        case .SharingDenied:
        //            return .Unauthorized
        //        case .NotDetermined:
        //            return .Unknown
        //        }
        return .Unknown
    }
    
    func requestHealthKit() {
        //        switch statusHealth() {
        //        case .Unknown:
        //            HKHealthStore().requestAuthorizationToShareTypes(<#typesToShare: Set<NSObject>!#>,
        //                readTypes: <#Set<NSObject>!#>,
        //                completion: <#((Bool, NSError!) -> Void)!##(Bool, NSError!) -> Void#>)
        //            EKEventStore().requestAccessToEntityType(EKEntityTypeEvent,
        //                completion: { (granted, error) -> Void in
        //                    self.detectAndCallback()
        //            })
        //        case .Unauthorized:
        //            self.showDeniedAlert(.Reminders)
        //        default:
        //            break
        //        }
    }
    
    // MARK: - UI

    @objc public func show(authChange: ((finished: Bool, results: [PermissionResult]) -> Void)? = nil, cancelled: ((results: [PermissionResult]) -> Void)? = nil) {
        assert(configuredPermissions.count > 0, "Please add at least one permission")

        authChangeClosure = authChange
        cancelClosure = cancelled 

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            while self.waitingForBluetooth || self.waitingForMotion {}
            // call other methods that need to wait before show
            dispatch_async(dispatch_get_main_queue()) {
                // no missing required perms? callback and do nothing
                if self.requiredAuthorized {
                    self.authChangeClosure?(true, self.getResultsForConfig())
                } else {
                    self.showAlert()
                }
            }
        }
    }
    
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

    // MARK: - Gesture delegate

    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {

        // this prevents our tap gesture from firing for subviews of baseview
        if touch.view == baseView {
            return true
        }

        return false
    }

    // MARK: - Location delegate

    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {

        detectAndCallback()
    }
    
    // MARK: - Bluetooth delegate
    
    public func peripheralManagerDidUpdateState(peripheral: CBPeripheralManager) {
        
        waitingForBluetooth = false
        detectAndCallback()
    }

    // MARK: - UI Helpers
    
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
    
    func appForegroundedAfterSettings (){
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidBecomeActiveNotification, object: nil)
        
        detectAndCallback()
    }
    
    func showDeniedAlert(permission: PermissionType) {
        if let disabledOrDeniedClosure = self.disabledOrDeniedClosure {
            disabledOrDeniedClosure(self.getResultsForConfig())
        }
        let alert = UIAlertController(title: "Permission for \(permission.description) was denied.",
            message: "Please enable access to \(permission.description) in the Settings app",
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
        let alert = UIAlertController(title: "\(permission.description) is currently disabled.",
            message: "Please enable access to \(permission.description) in Settings",
            preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: .Cancel,
            handler: nil))
        viewControllerForAlerts?.presentViewController(alert,
            animated: true, completion: nil)
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
        case .Motion:
            return statusMotion()
        case .HealthKit:
            return statusHealthKit()
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
            let status = statusForPermission(config.type)
            let result = PermissionResult(type: config.type, status: status, demands: config.demands)
            results.append(result)
        }
        
        return results
    }
}
