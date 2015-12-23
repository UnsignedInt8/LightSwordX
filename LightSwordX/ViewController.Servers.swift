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
        server.isDefault = servers.count == 0 ? true : false
        
        servers.append(server)
        serversTableView.reloadData()
        serverDetailsView.hidden = false

        let indexSet = NSIndexSet(index: servers.count - 1)
        serversTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
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
        servers.forEach{ s in s.isDefault = false }
        selectedServer.isDefault = !selectedServer.isDefault
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {

        let info = servers[row]
        
        serverAddressTextField.stringValue = info.address
        serverPortTextField.stringValue = String(info.port)
        cipherAlgorithmComboBox.stringValue = info.cipherAlgorithm
        passwordTextField.stringValue = info.password
        setAsDefaultCheckBox.state = info.isDefault ? NSOnState : NSOffState
        
        selectedServer = info
        return true
    }
}

extension ViewController: NSComboBoxDelegate {
    
    override func controlTextDidChange(obj: NSNotification) {
        let textField = obj.object as! NSTextField
        var newValue = textField.stringValue
        
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
            
        default:
            return
        }
        
        isDirty = true
    }
    
    override func controlTextDidEndEditing(obj: NSNotification) {
        if !isDirty {
            return
        }
        
        let dict = servers.map{ s in return ["address": s.address, "port": s.port, "cipherAlgorithm": s.cipherAlgorithm, "password": s.password, "isDefault": s.isDefault] }
        SettingsHelper.saveValue(JSON(dict).toString(), forKey: serversKey)
        isDirty = false
    }
    
    func comboBoxSelectionDidChange(notification: NSNotification) {
        let comboBox = notification.object as! NSComboBox
        
        if (comboBox.identifier != "cipherAlgorithm") {
            return
        }
        
        let methods = ["aes-256-cfb", "aes-192-cfb", "aes-128-cfb"]
        let selectedIndex = comboBox.indexOfSelectedItem
        selectedServer.cipherAlgorithm = methods[selectedIndex]
    }
}
