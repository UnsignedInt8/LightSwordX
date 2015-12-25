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
        server.id = servers.count
        server.keepConnection = servers.count == 0 ? true : false
        
        servers.append(server)
        serversTableView.reloadData()
        
        let indexSet = NSIndexSet(index: servers.count - 1)
        serversTableView.selectRowIndexes(indexSet, byExtendingSelection: false)
        
        serverDetailsView.hidden = false
        keepConnectionCheckBox.state = server.keepConnection ? NSOnState : NSOffState
        serverAddressTextField.stringValue = server.address
        serverPortTextField.stringValue = String(server.port)
        cipherAlgorithmComboBox.stringValue = server.cipherAlgorithm
        proxyModeComboBox.selectItemAtIndex(server.proxyMode.rawValue)
        passwordTextField.stringValue = server.password
        listenAddressTextField.stringValue = server.listenAddr
        listenPortTextField.stringValue = String(server.listenPort)
        
        saveServers(true)

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
        
        saveServers(true)
    }
    
    @IBAction func setAsDefaultServer(sender: NSButton) {
        let selectedServer = servers[selectedRow]
        
        selectedServer.keepConnection = !selectedServer.keepConnection
        saveServers(true)
        
        if selectedServer.keepConnection {
            startServer(selectedServer)
            return
        }
        
        stopServerId(selectedServer)
    }
}

extension ViewController: NSTableViewDelegate {
    func tableView(tableView: NSTableView, shouldSelectRow row: Int) -> Bool {

        let info = servers[row]
        selectedRow = row
        
        serverAddressTextField.stringValue = info.address
        serverPortTextField.stringValue = String(info.port)
        cipherAlgorithmComboBox.stringValue = info.cipherAlgorithm
        proxyModeComboBox.selectItemAtIndex(info.proxyMode.rawValue)
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
            } else if (newValue == "localhost") {
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
        let handlers = [
            "cipherAlgorithm": cipherAlgorithmComboBoxChanged,
            "proxyMode": proxyModeComboBoxChanged
        ]
        
        handlers[comboBox.identifier!]?(comboBox)
    }
    
    private func cipherAlgorithmComboBoxChanged(comboBox: NSComboBox) {
        let methods = ["aes-256-cfb", "aes-192-cfb", "aes-128-cfb"]
        let selectedIndex = comboBox.indexOfSelectedItem
        if (servers[selectedRow].cipherAlgorithm == methods[selectedIndex]) {
            return
        }
        
        servers[selectedRow].cipherAlgorithm = methods[selectedIndex]
        isDirty = true
    }
    
    private func proxyModeComboBoxChanged(comboBox: NSComboBox) {
        let modes = [
            ProxyMode.GLOBAL.rawValue: ProxyMode.GLOBAL,
            ProxyMode.BLACK.rawValue: ProxyMode.BLACK,
            ProxyMode.WHITE.rawValue: ProxyMode.WHITE
        ]
        
        let selectedIndex = comboBox.indexOfSelectedItem
        if let selectedMode = modes[selectedIndex] {
            if (servers[selectedRow].proxyMode == selectedMode) {
                return
            }
            
            servers[selectedRow].proxyMode = selectedMode
            isDirty = true
        }
    }
}
