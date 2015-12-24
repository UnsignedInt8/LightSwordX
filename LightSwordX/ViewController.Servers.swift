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
        let server = UserServer()
        server.keepConnection = servers.count == 0 ? true : false
        
        servers.append(server)
        serversTableView.reloadData()
        serverDetailsView.hidden = false
        keepConnectionCheckBox.state = server.keepConnection ? NSOnState : NSOffState
        listenAddressTextField.stringValue = server.listenAddr
        listenPortTextField.stringValue = String(server.listenPort)

        let indexSet = NSIndexSet(index: servers.count - 1)
        serversTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        
        if (server.keepConnection) {
            startServer(server)
        }
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
    
    @IBAction func setAsDefaultServer(sender: NSButton) {
        let selectedServer = servers[selectedRow]
        
        selectedServer.keepConnection = !selectedServer.keepConnection
        saveServers()
        
        if selectedServer.keepConnection {
            startServer(selectedServer)
            return
        }
        
        stopServer(selectedServer)
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {

        let info = servers[row]
        selectedRow = row
        
        serverAddressTextField.stringValue = info.address
        serverPortTextField.stringValue = String(info.port)
        cipherAlgorithmComboBox.stringValue = info.cipherAlgorithm
        passwordTextField.stringValue = info.password
        keepConnectionCheckBox.state = info.keepConnection ? NSOnState : NSOffState
        listenAddressTextField.stringValue = info.listenAddr
        listenPortTextField.stringValue = String(info.listenPort)
        
        saveServers()
        return true
    }
}

extension ViewController: NSComboBoxDelegate {
    
    override func controlTextDidChange(obj: NSNotification) {
        let textField = obj.object as! NSTextField
        var newValue = textField.stringValue
        let selectedServer = servers[selectedRow]
        
        switch textField.identifier! {
            
        case "serverAddress":
            if (newValue.length == 0) {
                newValue = "127.0.0.1"
            }
            
            selectedServer.address = newValue
            serversTableView.reloadData()
            break
            
        case "serverPort":
            let port = Int(newValue) ?? 8900
            selectedServer.port = port
            serverPortTextField.stringValue = String(port)
            break
            
        case "password":
            if (newValue.length == 0) {
                newValue = "lightsword.neko"
            }
            
            selectedServer.password = newValue
            break
            
        case "listenAddr":
            if (newValue.length == 0) {
                newValue = "127.0.0.1"
            }
            
            selectedServer.listenAddr = newValue
            listenAddressTextField.stringValue = newValue
            break
            
        case "listenPort":
            let port = Int(newValue) ?? 1080
            selectedServer.listenPort = port
            listenPortTextField.stringValue = String(port)
            break
            
        default:
            return
        }
        
        isDirty = true
    }
    
    override func controlTextDidEndEditing(obj: NSNotification) {
        saveServers()
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        let comboBox = notification.object as! NSComboBox
        
        if (comboBox.identifier != "cipherAlgorithm") {
            return
        }
        
        let methods = ["aes-256-cfb", "aes-192-cfb", "aes-128-cfb"]
        let selectedIndex = comboBox.indexOfSelectedItem
        servers[selectedRow].cipherAlgorithm = methods[selectedIndex]
    }
}
