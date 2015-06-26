# PermissionScope 🔐🔭

[![Language](http://img.shields.io/badge/language-swift-brightgreen.svg?style=flat
)](https://developer.apple.com/swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Cocoapods compatible](https://cocoapod-badges.herokuapp.com/v/PermissionScope/badge.png)](https://cocoapods.org/pods/PermissionScope)
[![License](http://img.shields.io/badge/license-MIT-lightgrey.svg?style=flat
)](http://mit-license.org)

Inspired by (but unrelated to) [Periscope](https://www.periscope.tv)'s permission control, PermissionScope is a Swift framework for intelligently requesting permissions from users. **It contains not only a simple UI to request permissions but also a unified permissions API** that can tell you the status of any given system permission or easily request them.

Some examples of multiple permissions requests, a single permission and the denied alert.

<img src="http://raquo.net/images/permissionscope.gif" alt="permissionscope gif" />

We should all be more careful about when we request permissions from users, opting to request them only when they're needed and definitely not all in one barrage when the user opens the app for the first time.

PermissionScope gives you space to explain your reasons for requesting their precious permissions and allows users to tackle the system dialogs at their own pace. It conforms to (what I hope will be) a standard permissions design but is flexible enough to fit in to most UIKit-based apps.

Best of all, PermissionScope detects when ([some of](https://github.com/nickoneill/PermissionScope/issues/9)) your permissions have been denied by a user and gives them an easy prompt to go into the system settings page to modify these permissions.

## installation

* requires iOS 8+

Installation for [Carthage](https://github.com/Carthage/Carthage) is simple enough:

`github "nickoneill/PermissionScope" ~> 0.6`

As for [Cocoapods](https://cocoapods.org), use this to get the latest code:

`pod 'PermissionScope', '~> 0.6'`

And `import PermissionScope` in the files you'd like to use it.

No promises that it works with Obj-C at the moment, I'm using it with a mostly-Swift codebase. Feedback on this would be great though.

## dialog usage

The simplest implementation displays a list of permissions and is removed when all of them have satisfactory access.

```swift
class ViewController: UIViewController {
    let pscope = PermissionScope()

    override func viewDidLoad() {
        super.viewDidLoad()

        pscope.addPermission(PermissionConfig(type: .Contacts, demands: .Required, message: "We use this to steal\r\nyour friends"))
        pscope.addPermission(PermissionConfig(type: .Notifications, demands: .Optional, message: "We use this to send you\r\nspam and love notes", notificationCategories: .None))
        pscope.addPermission(PermissionConfig(type: .LocationInUse, demands: .Required, message: "We use this to track\r\nwhere you live"))

        pscope.show()
    }

    @IBAction func doAThing() {
        pscope.show(authChange: { (finished, results) -> Void in
            println("got results \(results)")
        }, cancelled: { (results) -> Void in
            println("thing was cancelled")
        })
    }
}
```

The permissions view will automatically show if there are permissions to approve and will take no action if permissions are already granted. It will automatically hide when all permissions have been approved.

If you're attempting to block access to a screen in your app without permissions (like, say, the broadcast screen in Periscope), you should watch for the cancel closure and take an appropriate action for your app.

A permission can either have `.Required` or .`Optional` demands. Required permissions (such as access to contacts for a contact picker) are evaluated when you call `show` and, if all required demands are met, the dialog isn't shown!

A permission with the `.Optional` demand will not cause the dialog to show alone. Users who have accepted all the required permissions but not all optional permissions can tap out to continue without allowing the optional permissions.

### customizability

You can easily change the colors, label and buttons fonts with PermissionScope.

```swift
pscope.tintColor = UIColor...
pscope.headerLabel.text = "..."
pscope.headerLabel.font = UIFont...
pscope.bodyLabel.text = "..."
pscope.bodyLabel.font = UIFont...
pscope.buttonFont = UIFont...
pscope.labelFont = UIFont...
```

In addition, the default behavior for tapping the background behind the dialog is to cancel the dialog (which calls the cancel closure you can provide on `show`). You can change this behavior with `backgroundTapCancels` during init.

### unified permissions API

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

You will probably also want to set the `authChangeClosure`, `cancelClosure`, and `disabledOrDeniedClosure` closures, which are called at the appropriate times when the `request*` methods are finished, otherwise you won't know when the work has been completed.

```swift
pscope.authChangeClosure = { (finished, results) -> Void in
	println("Request was finished with results \(results)")
	if results[0].status == .Authorized {
		println("They've authorized the use of notifications")
		UIApplication.sharedApplication().registerForRemoteNotifications()
	}
}
pscope.cancelClosure = { (results) -> Void in
	println("Request was cancelled with results \(results)")
}
pscope.disabledOrDeniedClosure = { (results) -> Void in
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

### issues

* You get "Library not loaded: @rpath/libswiftCoreAudio.dylib", "image not found" errors when your app runs:

PermissionScope imports CoreAudio to request microphone access but it's not automatically linked in if your app doesn't `import CoreAudio` somewhere. I'm not sure if this is a bug or a a quirk of how CoreAudio is imported. For now, if you `import CoreAudio` in your top level project it should fix the issue.

### beta
We're using PermissionScope in [treat](https://gettre.at) and fixing issues as they arise. Still, there's definitely some beta-ness around and the API can change without warning. Check out what we have planned in [issues](http://github.com/nickoneill/PermissionScope/issues) and contribute a suggestion or some code 😃

### PermissionScope registers user notification settings, not remote notifications
Users will get the prompt to enable notifications when using PermissionScope but it's up to you to watch for results in your app delegate's `didRegisterUserNotificationSettings` and then register for remote notifications independently. This won't alert the user again. You're still responsible for handling the shipment of user notification settings off to your push server.

### notes about location
**You must set these Info.plist keys for location to work**

Trickiest part of implementing location permissions? You must implement the proper key in your Info.plist file with a short description of how your app uses location info (shown in the system permissions dialog). Without this, trying to get location  permissions will just silently fail. *Software*!

Use `NSLocationAlwaysUsageDescription` or `NSLocationWhenInUseUsageDescription` where appropriate for your app usage. You can specify which of these location permissions you wish to request with `.LocationAlways` or `.LocationInUse` while configuring PermissionScope.

### notes about bluetooth
The *NSBluetoothPeripheralUsageDescription* key in the Info.plist specifying a short description of why your app needs to act as a bluetooth peripheralin the background is **optional**. 

However, enabling `background-modes` in the capabilities section and checking the `acts as a bluetooth LE accessory` checkbox is **required**.


### license, etc

PermissionScope uses the MIT license. Please file an issue if you have any questions or if you'd like to share how you're using this tool.
