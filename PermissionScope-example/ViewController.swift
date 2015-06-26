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
    let singlePscope = PermissionScope()
    let multiPscope = PermissionScope()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        singlePscope.addPermission(PermissionConfig(type: .Notifications, demands: .Required, message: "We use this to send you\r\nspam and love notes", notificationCategories: .None))

        multiPscope.addPermission(PermissionConfig(type: .Contacts, demands: .Required, message: "We use this to steal\r\nyour friends"))
        multiPscope.addPermission(PermissionConfig(type: .Notifications, demands: .Required, message: "We use this to send you\r\nspam and love notes", notificationCategories: .None))
//        multiPscope.addPermission(PermissionConfig(type: .LocationInUse, demands: .Required, message: "We use this to track\r\nwhere you live"))
        multiPscope.addPermission(PermissionConfig(type: .Bluetooth, demands: .Required, message: "We use this to drain your battery"))

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // an example of how to use the unified permissions API
    func checkContacts() {
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
    }
    
    @IBAction func singlePerm() {
        singlePscope.show(authChange: { (finished, results) -> Void in
            println("got results \(results)")
        }, cancelled: { (results) -> Void in
            println("thing was cancelled")
        })
    }

    @IBAction func multiPerms() {
        multiPscope.show(authChange: { (finished, results) -> Void in
            println("got results \(results)")
        }, cancelled: { (results) -> Void in
            println("thing was cancelled")
        })
    }
}

