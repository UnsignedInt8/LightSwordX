//
//  UserServersDataSource.swift
//  LightSwordX
//
//  Created by Neko on 12/23/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa

extension ViewController: NSTableViewDataSource {
    
    
    @objc func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return servers.count
    }
    
    @objc func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        return servers[row].address
    }
    
    @IBAction func addServer(sender: NSButton) {
        servers.append(UserServer())
        serversTableView.reloadData()
        serverDetailsView.hidden = false
    }
    
    @IBAction func removeServer(sender: NSButton) {
        let selectedRow = serversTableView.selectedRow
        if (selectedRow == -1) {
            return
        }
        
        servers.removeAtIndex(selectedRow)
        serversTableView.reloadData()
        
        if (servers.count == 0) {
            serverDetailsView.hidden = true
        }
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        print(row)
        return true
    }
}
