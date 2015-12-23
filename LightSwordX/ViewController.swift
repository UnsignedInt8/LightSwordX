//
//  ViewController.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa
import SINQ

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        serverDetailsView.hidden = true
    }
    
    override func awakeFromNib() {
        
        let jsonStr = SettingsHelper.loadValue(defaultValue: "", forKey: self.serversKey)
        
        if (jsonStr.length == 0) {
            self.servers = [UserServer]()
            return
        }
        
        let jObjs = JSON(string: jsonStr)
        self.servers = jObjs.map{ obj, jObj in
            let server = UserServer()
            server.address = jObj["address"].asString!
            server.port = jObj["port"].asInt!
            server.cipherAlgorithm = jObj["cipherAlgorithm"].asString!
            server.password = jObj["password"].asString!
            
            return server
        }
        
        if let defaultServer = sinq(servers).firstOrNil({ s in s.isDefault }) {
            startServer(defaultServer)
        }
    }
    
    let serversKey = "Servers";
    var servers: [UserServer]!
    var selectedServer: UserServer!
    
    @IBOutlet weak var serversTableView: NSTableView!
    @IBOutlet weak var serverDetailsView: NSView!
    @IBOutlet weak var serverAddressTextField: NSTextField!
    @IBOutlet weak var serverPortTextField: NSTextField!
    @IBOutlet weak var cipherAlgorithmComboBox: NSComboBox!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var setAsDefaultCheckBox: NSButton!
    @IBOutlet weak var connectionStatus: NSTextField!
    
    func startServer(info: UserServer) {
        let server = Socks5Server()
        server.listenAddr = "127.0.0.1"
        server.listenPort = 2002
        server.serverAddr = "silver.local"//"localhost"
        server.serverPort = 8900
        server.bypassLocal = true
        server.cipherAlgorithm = "aes-256-cfb"
        server.password = "lightsword.neko"
        server.timeout = 60 * 1000
        server.start()
    }
}

