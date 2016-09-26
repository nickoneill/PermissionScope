<p align="center">
    <img src="http://raquo.net/images/banner.png" alt="PermissionScope" />
</p>

<p align="center">
    <img src="https://img.shields.io/badge/platform-iOS%208%2B-blue.svg?style=flat" alt="Platform: iOS 8+" />
    <a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/language-swift3-f48041.svg?style=flat" alt="Language: Swift 3" /></a>
    <a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
    <a href="https://cocoapods.org/pods/PermissionScope"><img src="https://cocoapod-badges.herokuapp.com/v/PermissionScope/badge.png" alt="Cocoapods compatible" /></a>
    <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat" alt="License: MIT" />
</p>

<p align="center">
    <a href="#installation">Installation</a>
  • <a href="#dialog-usage">Usage</a>
  • <a href="#customization">Customization</a>
  • <a href="#known-bugs">Known bugs</a>
  • <a href="https://github.com/nickoneill/PermissionScope/issues">Issues</a>
  • <a href="#license">License</a>
</p>

Inspired by (but unrelated to) [Periscope](https://www.periscope.tv)'s permission control, PermissionScope is a Swift framework for intelligently requesting permissions from users. **It contains not only a simple UI to request permissions but also a unified permissions API** that can tell you the status of any given system permission or easily request them.

Some examples of multiple permissions requests, a single permission and the denied alert.

<p align="center">
    <img src="http://raquo.net/images/permissionscope.gif" alt="permissionscope gif" />
</p>

PermissionScope **gives you space to explain your reasons for requesting permissions** and **allows users to tackle the system dialogs at their own pace**. It presents a straightforward permissions design and is flexible enough to fit in to most UIKit-based apps.

Best of all, PermissionScope detects when your app's permissions have been denied by a user and gives them an easy prompt to go into the system settings page to modify these permissions.

## compatibility

PermissionScope requires iOS 8+, compatible with both **Swift 3** and **Objective-C** based projects

For Swift 2.x support, please use the swift2 branch or the 1.0.2 release version. This branch was up-to-date on 9/6/16 but is not being maintained. All future efforts will go towards Swift 3 development.

## installation

Installation for [Carthage](https://github.com/Carthage/Carthage) is simple enough:

`github "nickoneill/PermissionScope" ~> 1.0`

As for [Cocoapods](https://cocoapods.org), use this to get the latest release:

```ruby
use_frameworks!

pod 'PermissionScope'
```

And `import PermissionScope` in the files you'd like to use it.

## dialog usage

The simplest implementation displays a list of permissions and is removed when all of them have satisfactory access.

```swift
class ViewController: UIViewController {
    let pscope = PermissionScope()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up permissions
        pscope.addPermission(ContactsPermission(),
            message: "We use this to steal\r\nyour friends")
        pscope.addPermission(NotificationsPermission(notificationCategories: nil),
            message: "We use this to send you\r\nspam and love notes")
        pscope.addPermission(LocationWhileInUsePermission(),
            message: "We use this to track\r\nwhere you live")
	
	// Show dialog with callbacks
        pscope.show({ finished, results in
            print("got results \(results)")
        }, cancelled: { (results) -> Void in
            print("thing was cancelled")
        })   
    }
}
```

The permissions view will automatically show if there are permissions to approve and will take no action if permissions are already granted. It will automatically hide when all permissions have been approved.

If you're attempting to block access to a screen in your app without permissions (like, say, the broadcast screen in Periscope), you should watch for the cancel closure and take an appropriate action for your app.

### customization

You can easily change the colors, label and buttons fonts with PermissionScope by modifying any of these properties:

Field | Type | Comment
----- | ---- | -------
headerLabel | UILabel | Header UILabel with the message "Hey, listen!" by default.
bodyLabel | UILabel | Header UILabel with the message "We need a couple things\r\nbefore you get started." by default.
closeButtonTextColor | UIColor | Color for the close button's text color.
permissionButtonTextColor  | UIColor | Color for the permission buttons' text color.
permissionButtonBorderColor | UIColor | Color for the permission buttons' border color.
buttonFont | UIFont | Font used for all the UIButtons
labelFont | UIFont | Font used for all the UILabels
closeButton | UIButton | Close button. By default in the top right corner.
closeOffset | CGSize | Offset used to position the Close button.
authorizedButtonColor | UIColor | Color used for permission buttons with authorized status
unauthorizedButtonColor | UIColor? | Color used for permission buttons with unauthorized status. By default, inverse of `authorizedButtonColor`.
permissionButtonΒorderWidth | CGFloat | Border width for the permission buttons.
permissionButtonCornerRadius | CGFloat | Corner radius for the permission buttons.
permissionLabelColor | UIColor | Color for the permission labels' text color.
contentView | UIView | Dialog's content view

In addition, the default behavior for tapping the background behind the dialog is to cancel the dialog (which calls the cancel closure you can provide on `show`). You can change this behavior with `backgroundTapCancels` during init.

If you'd like more control over the button text for a particular permission, you can [use a `.strings` file](https://github.com/nickoneill/PermissionScope/pull/12#issuecomment-96428580) for your intended language and override them that way. Please get in touch if you'd like to contribute a localization file for another language!

## unified permissions API

PermissionScope also has an abstracted API for getting the state for a given permission and requesting permissions if you need to do so outside of the normal dialog UI. Think of it as a unified iOS permissions API that can provide some features that even Apple does not (such as detecting denied notification permissions).

```swift
switch PermissionScope().statusContacts() {
case .Unknown:
    // ask
    PermissionScope().requestContacts()
case .Unauthorized, .Disabled:
    // bummer
    return
case .Authorized:
    // thanks!
    return
}
```

### calling `request*` methods directly

Normally PermissionScope is used to walk users through necessary permissions before they're allowed to do something in your app. Sometimes you may wish to instead call into the various `request*` permissions-seeking methods of PermissionScope directly, from your own UI.

To call these methods directly, you must first set the `viewControllerForAlerts` method to your current UIViewController, in case PermissionScope needs to present some alerts to the user for denied or disabled permissions:

```swift
let pscope = PermissionScope()
pscope.viewControllerForAlerts = self
```

You will probably also want to set the `onAuthChange`, `onCancel`, and `onDisabledOrDenied` closures, which are called at the appropriate times when the `request*` methods are finished, otherwise you won't know when the work has been completed.

```swift
pscope.onAuthChange = { (finished, results) in
	println("Request was finished with results \(results)")
	if results[0].status == .Authorized {
		println("They've authorized the use of notifications")
		UIApplication.sharedApplication().registerForRemoteNotifications()
	}
}
pscope.onCancel = { results in
	println("Request was cancelled with results \(results)")
}
pscope.onDisabledOrDenied = { results in
	println("Request was denied or disabled with results \(results)")
}
```

And then you might call it when the user toggles a switch:

```swift
@IBAction func notificationsChanged(sender: UISwitch) {
	if sender.on {
		// turn on notifications
		if PermissionScope().statusNotifications() == .Authorized {
			UIApplication.sharedApplication().registerForRemoteNotifications()
		} else {
			pscope.requestNotifications()
		}
	} else {
	    // turn off notifications
	}
```
If you're also using PermissionScope in the traditional manner, don't forget to set viewControllerForAlerts back to it's default, the instance of PermissionScope. The easiest way to do this is to set it explicitly before you call a `request*` method, and then reset it in your closures.

```swift
pscope.viewControllerForAlerts = pscope as UIViewController
```

### PermissionScope registers user notification settings, not remote notifications
Users will get the prompt to enable notifications when using PermissionScope but it's up to you to watch for results in your app delegate's `didRegisterUserNotificationSettings` and then register for remote notifications independently. This won't alert the user again. You're still responsible for handling the shipment of user notification settings off to your push server.

## extra requirements for permissions

### location 
**You must set these Info.plist keys for location to work**

Trickiest part of implementing location permissions? You must implement the proper key in your Info.plist file with a short description of how your app uses location info (shown in the system permissions dialog). Without this, trying to get location  permissions will just silently fail. *Software*!

Use `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` where appropriate for your app usage. You can specify which of these location permissions you wish to request with `.LocationAlways` or `.LocationInUse` while configuring PermissionScope.

### bluetooth

The *NSBluetoothPeripheralUsageDescription* key in the Info.plist specifying a short description of why your app needs to act as a bluetooth peripheral in the background is **optional**.

However, enabling `background-modes` in the capabilities section and checking the `acts as a bluetooth LE accessory` checkbox is **required**.

### healthkit

Enable `HealthKit` in your target's capabilities, **required**.

## known bugs

* ITC app rejection with the following reason: "*This app attempts to access privacy-sensitive data without a usage description*". ([#194](https://github.com/nickoneill/PermissionScope/issues/194))

Solution: TBD

* When the user is taken to the Settings.app, if any of the app's permissions are changed (whilst the app was in the background), the app will crash. ([#160](https://github.com/nickoneill/PermissionScope/issues/160))

Solution: None. Works as intended by the OS.

* Link "**Show me**" does not work on denied a permission ([#61](https://github.com/nickoneill/PermissionScope/issues/61))

Solution: Run your app without the debugger.

* When using **Carthage**, the following error occurs: *Module file was created by an older version of the compiler*.

Solution: Use the `--no-use-binaries` flag (e.g:  `carthage update --no-use-binaries`).

## license

PermissionScope uses the MIT license. Please file an issue if you have any questions or if you'd like to share how you're using this tool.
