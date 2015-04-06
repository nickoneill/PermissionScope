//
//  ModalPerms.swift
//  modalperms
//
//  Created by Nick O'Neill on 4/5/15.
//  Copyright (c) 2015 That Thing in Swift. All rights reserved.
//

import Foundation

public enum PermissionType {
    case Contacts
    case Location
    case Microphone
    case Camera
    case Notifications
}

public struct PermissionConfig {
    let type: PermissionType
    let message: String

    public init(type: PermissionType, message: String) {
        self.type = type
        self.message = message
    }
}

public class ModalPerms: UIViewController {
    // constants
    let ContentWidth: CGFloat = 280.0
    let ContentHeight: CGFloat = 480.0

    public let headerLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
    public let bodyLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 240, height: 80))
    public var tintColor = UIColor(red: 0, green: 0.47, blue: 1, alpha: 1)

    let baseView = UIView()
    let contentView = UIView()

    var configuredPermissions: [PermissionConfig] = []

    public override init() {
        super.init()
        // Set up main view
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.7)
        view.addSubview(baseView)
        // Base View
        baseView.frame = view.frame
        baseView.addSubview(contentView)
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
        bodyLabel.text = "We need a couple things before you get started."
        bodyLabel.numberOfLines = 4
//        bodyLabel.text = "We need\r\na couple things\r\nbefore you\r\nget started."
//        bodyLabel.backgroundColor = UIColor.redColor()

        contentView.addSubview(bodyLabel)
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        var sz = UIScreen.mainScreen().bounds.size
        // Set background frame
        view.frame.size = sz
        // Set frames
        var x = (sz.width - ContentWidth) / 2
        var y = (sz.height - ContentHeight) / 2
        contentView.frame = CGRect(x:x, y:y, width:ContentWidth, height:ContentHeight)

        // offset the header from the content center, compensate for the content's offset
        headerLabel.center = contentView.center
        headerLabel.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        headerLabel.frame.offset(dx: 0, dy: -200)

        // ... same with the body
        bodyLabel.center = contentView.center
        bodyLabel.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
        bodyLabel.frame.offset(dx: 0, dy: -120)

        let baseOffset = 95
        var index = 0
        for config in configuredPermissions {
            let button = permissionStyledButton(config.type)
            button.center = contentView.center
            button.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            button.frame.offset(dx: 0, dy: -30 + CGFloat(index * baseOffset))
            contentView.addSubview(button)

            let label = permissionStyledLabel(config.message)
            label.center = contentView.center
            label.frame.offset(dx: -contentView.frame.origin.x, dy: -contentView.frame.origin.y)
            label.frame.offset(dx: 0, dy: 15 + CGFloat(index * baseOffset))
            contentView.addSubview(label)

            index++
        }
    }


    // MARK: customizing the permissions

    public func addPermission(config: PermissionConfig) {
        assert(!config.message.isEmpty, "Including a message about your permission is helpful")
        assert(configuredPermissions.count < 3, "Ask for three or fewer permissions at a time")

        configuredPermissions.append(config)
    }

    func permissionStyledButton(type: PermissionType) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 220, height: 40))
        button.setTitleColor(tintColor, forState: UIControlState.Normal)
        button.titleLabel?.font = UIFont.boldSystemFontOfSize(14)

        button.layer.borderWidth = 1
        button.layer.borderColor = tintColor.CGColor
        button.layer.cornerRadius = 6

        switch type {
        case .Contacts:
            button.setTitle("Allow Contacts".uppercaseString, forState: UIControlState.Normal)
        case .Location:
            button.setTitle("Enable Location".uppercaseString, forState: UIControlState.Normal)
        case .Notifications:
            button.setTitle("Enable Notifications".uppercaseString, forState: UIControlState.Normal)
        case .Microphone:
            button.setTitle("Allow Microphone".uppercaseString, forState: UIControlState.Normal)
        case .Camera:
            button.setTitle("Allow Camera".uppercaseString, forState: UIControlState.Normal)
        }

        return button
    }

    func permissionStyledLabel(message: String) -> UILabel {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 260, height: 50))
        label.font = UIFont.systemFontOfSize(14)
        label.numberOfLines = 2
        label.textAlignment = NSTextAlignment.Center

        label.text = message
//        label.backgroundColor = UIColor.greenColor()

        return label
    }

    // MARK: finally, displaying the panel

    public func show() {
        view.alpha = 0
        let rv = UIApplication.sharedApplication().keyWindow!
        rv.addSubview(view)
        view.frame = rv.bounds
        baseView.frame = rv.bounds

        // Animate in the alert view
        self.baseView.frame.origin.y = -400
        UIView.animateWithDuration(0.2, animations: {
            self.baseView.center.y = rv.center.y + 15
            self.view.alpha = 1
        }, completion: { finished in
            UIView.animateWithDuration(0.2, animations: {
                self.baseView.center = rv.center
            })
        })
    }

    public func hide() {
        let rv = UIApplication.sharedApplication().keyWindow!

        UIView.animateWithDuration(0.2, animations: {
            self.baseView.frame.origin.y = rv.center.y + 400
            self.view.alpha = 0
        }, completion: { finished in
            self.view.removeFromSuperview()
        })
    }

    public func somethingElse() {
        println("ok")
    }

    public func doSomething() {
        println("Yeah, it works")
    }
}
