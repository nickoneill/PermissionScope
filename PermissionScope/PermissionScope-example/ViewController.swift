//
//  ViewController.swift
//  PermissionScope-example
//
//  Created by Nick O'Neill on 4/5/15.
//  Copyright (c) 2015 That Thing in Swift. All rights reserved.
//

import UIKit
import PermissionScope

class ViewController: UIViewController {
    let pscope = PermissionScope()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func doAThing() {
        pscope.addPermission(PermissionConfig(type: .Contacts, message: "We use this to steal\r\nyour friends"))
        pscope.addPermission(PermissionConfig(type: .Notifications, message: "We use this to send you\r\nspam and love notes"))
        pscope.addPermission(PermissionConfig(type: .LocationAlways, message: "We use this to track\r\nwhere you live"))

        pscope.show({ (results) -> Void in
            println("got results \(results)")
        }, cancelled: { () -> Void in
            println("thing was cancelled")
        })
    }
}

