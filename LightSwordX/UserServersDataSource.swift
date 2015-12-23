//
//  UserServersDataSource.swift
//  LightSwordX
//
//  Created by Neko on 12/23/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa

class UserServersDataSource: NSObject, NSTableViewDataSource {
    
    private let serversKey = "Servers";
    var servers: [UserServer]!
    
    override init() {
        super.init()
        let jsonStr = SettingsHelper.loadValue(defaultValue: "", forKey: serversKey)
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
    
    @objc func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return servers.count
    }
    
    @objc func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return servers[row]
    }
}
