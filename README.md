# PermissionScope

Inspired by (but unrelated to) [Periscope](https://www.periscope.tv)'s permission control, PermissionScope is a Swift framework for intelligently requesting permissions from users.

We should all be more careful about when we request permissions from users, opting to request them only when they're needed and definitely not all in one barrage when the user opens the app for the first time.

PermissionScope gives you space to explain your reasons for requesting their precious permissions and allows users to tackle the system dialogs at their own pace. It conforms to (what I hope will be) a standard permissions design but is flexible enough to fit in to most UIKit-based apps.

## installation

## usage

The simplest implementation displays a list of permissions and is removed when all of them have satisfactory access.

    let pscope = PermissionScope()
    pscope.addPermission(PermissionConfig(type: .Contacts, message: "We use this to steal\r\nyour friends"))
    pscope.addPermission(PermissionConfig(type: .Notifications, message: "We use this to send you\r\nspam and love notes"))
    pscope.addPermission(PermissionConfig(type: .LocationAlways, message: "We use this to track\r\nwhere you live"))
    
    pscope.show()

If you're attempting to block access to a screen in your app without permissions (like, say, the broadcast screen in Periscope), you should watch for the cancel closure and 

### You must set these Info.plist keys for location to work!
NSLocationAlwaysUsageDescription or NSLocationWhenInUseUsageDescription