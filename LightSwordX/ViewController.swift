//
//  ViewController.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        serverDetailsView.hidden = true
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func awakeFromNib() {
        
        let jsonStr = SettingsHelper.loadValue(defaultValue: "", forKey: self.serversKey)
        
        if (jsonStr.length == 0) {
            self.servers = [UserServer]()
            return
        }
        
        let servers = JSON(string: jsonStr)
        self.servers = servers.map{ obj, jObj in
            let server = UserServer()
            server.address = jObj["address"].asString!
            server.port = jObj["port"].asInt!
            server.cipherAlgorithm = jObj["cipherAlgorithm"].asString!
            server.password = jObj["password"].asString!
            
            return server
        }
    }
    
    let serversKey = "Servers";
    var servers: [UserServer]!
    
    @IBOutlet weak var serversTableView: NSTableView!
    @IBOutlet weak var serverDetailsView: NSView!
    @IBOutlet weak var serverAddressTextField: NSTextField!
    @IBOutlet weak var serverPortTextField: NSTextField!
    @IBOutlet weak var cipherAlgorithmComboBox: NSComboBox!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var setAsDefaultCheckBox: NSButton!
    
}

