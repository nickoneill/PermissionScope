# PermissionScope

Inspired by (but unrelated to) [Periscope](https://www.periscope.tv)'s permission control, PermissionScope is a Swift framework for intelligently requesting permissions from users.

![permissions screen](https://raw.githubusercontent.com/nickoneill/PermissionScope/master/permissions.png)

We should all be more careful about when we request permissions from users, opting to request them only when they're needed and definitely not all in one barrage when the user opens the app for the first time.

PermissionScope gives you space to explain your reasons for requesting their precious permissions and allows users to tackle the system dialogs at their own pace. It conforms to (what I hope will be) a standard permissions design but is flexible enough to fit in to most UIKit-based apps.

## installation

something something framework carthage

yada yada podspec not done yet

## usage

The simplest implementation displays a list of permissions and is removed when all of them have satisfactory access.

    let pscope = PermissionScope()
    pscope.addPermission(PermissionConfig(type: .Contacts, message: "We use this to steal\r\nyour friends"))
    pscope.addPermission(PermissionConfig(type: .Notifications, message: "We use this to send you\r\nspam and love notes"))
    pscope.addPermission(PermissionConfig(type: .LocationInUse, message: "We use this to track\r\nwhere you live"))
    
    pscope.show()

The permissions view will automatically show if there are permissions to approve and will take no action if permissions are already granted. It will automatically hide when all permissions have been approved.

If you're attempting to block access to a screen in your app without permissions (like, say, the broadcast screen in Periscope), you should watch for the cancel closure and take an appropriate action for your app.

### PermissionScope registers user notification settings, not remote notifications
Users will get the prompt to enable notifications when using PermissionScope but it's up to you to watch for results in your app delegate's `didRegisterUserNotificationSettings` and then register for remote notifications independently. This won't alert the user again. You're still responsible for handling the shipment of user notification settings off to your push server.

### You must set these Info.plist keys for location to work!
Trickiest part of implementing location permissions? You must implement the proper key in your Info.plist file with a short description of how your app uses location info (shown in the system permissions dialog). Without this, trying to get location  permissions will just silently fail. *Software*!

Use NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription where appropriate for your app usage. You can specify which of these location permissions you wish to request with `.LocationAlways` or `.LocationInUse` while configuring PermissionScope.
