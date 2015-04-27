//
//  ViewController.swift
//  PermissionScope-example
//
//  Created by Nick O'Neill on 4/5/15.
//  Copyright (c) 2015 That Thing in Swift. All rights reserved.
//

import UIKit
import CoreAudio
import PermissionScope

class ViewController: UIViewController {
    let pscope = PermissionScope()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        pscope.addPermission(PermissionConfig(type: .Contacts, demands: .Required, message: "We use this to steal\r\nyour friends"))
        pscope.addPermission(PermissionConfig(type: .Notifications, demands: .Optional, message: "We use this to send you\r\nspam and love notes", notificationCategories: .None))
        pscope.addPermission(PermissionConfig(type: .LocationInUse, demands: .Required, message: "We use this to track\r\nwhere you live"))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doAThing() {
        pscope.show(authChange: { (finished, results) -> Void in
            println("got results \(results)")
        }, cancelled: { (results) -> Void in
            println("thing was cancelled")
        })
    }
}

