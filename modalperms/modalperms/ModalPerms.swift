//
//  ModalPerms.swift
//  modalperms
//
//  Created by Nick O'Neill on 4/5/15.
//  Copyright (c) 2015 That Thing in Swift. All rights reserved.
//

import Foundation

public class ModalPerms: UIViewController {
    let kWindowWidth: CGFloat = 280.0
    var kWindowHeight: CGFloat = 480.0
    var kTextHeight: CGFloat = 90.0

    var baseView = UIView()
    var contentView = UIView()

    public override init() {
        super.init()
        // Set up main view
        view.frame = UIScreen.mainScreen().bounds
        view.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        view.backgroundColor = UIColor(red:0, green:0, blue:0, alpha:0.7)
        view.addSubview(baseView)
        // Base View
        baseView.frame = view.frame
        //        baseView.backgroundColor = UIColor.redColor()
        baseView.addSubview(contentView)
        // Content View
        contentView.backgroundColor = UIColor.whiteColor()
        contentView.layer.cornerRadius = 10
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 0.5
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
        var x = (sz.width - kWindowWidth) / 2
        var y = (sz.height - kWindowHeight) / 2
        contentView.frame = CGRect(x:x, y:y, width:kWindowWidth, height:kWindowHeight)
    }

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
