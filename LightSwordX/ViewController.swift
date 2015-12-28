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
        serverDetailsView.hidden = servers.count == 0 ? true : false
    }
    
    override func awakeFromNib() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            self.initBlackWhiteList()
        }
        
        if (servers != nil && servers.count > 0) {
            return
        }
        
        let jsonStr = SettingsHelper.loadValue(defaultValue: "", forKey: self.serversKey)
        
        if (jsonStr.length == 0) {
            self.servers = [UserServer]()
            return
        }
        
        let jObjs = JSON(string: jsonStr)
        var index = 0
        self.servers = jObjs.map{ obj, jObj in
            let server = UserServer()
            
            server.address = jObj["address"].asString!
            server.port = jObj["port"].asInt!
            server.cipherAlgorithm = jObj["cipherAlgorithm"].asString!
            server.password = jObj["password"].asString!
            server.keepConnection = jObj["keepConnection"].asBool!
            server.listenAddr = jObj["listenAddr"].asString!
            server.listenPort = jObj["listenPort"].asInt!
            server.proxyMode = ProxyMode(rawValue: jObj["proxyMode"].asInt ?? 0)!
            server.id = index++
            
            return server
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.servers.filter({ s in return s.keepConnection }).forEach { s in
                self.startServer(s)
            }
        }
    }
    
    func initBlackWhiteList() {
        let whiteList = SettingsHelper.loadValue(defaultValue: "", forKey: self.whiteKey)
        let blackList = SettingsHelper.loadValue(defaultValue: "", forKey: self.blackKey)
        
        if whiteList.length == 0 && blackList.length == 0 {
            ["white", "black"].forEach { s in
                let path = NSBundle.mainBundle().pathForResource(s, ofType: "txt")!
                let content = try! NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding)
                let list = content.componentsSeparatedByString("\n")
                if s == "white" {
                    self.whiteList = list
                    SettingsHelper.saveValue(content, forKey: self.whiteKey)
                } else {
                    self.blackList = list
                    SettingsHelper.saveValue(content, forKey: self.blackKey)
                }
            }
        } else {
            self.whiteList = whiteList.componentsSeparatedByString("\n")
            self.blackList = blackList.componentsSeparatedByString("\n")
        }
    }
    
    @IBAction func onCloseClick(sender: NSButton) {
        NSApplication.sharedApplication().windows.last?.close()
        saveServers()
        saveWebsites()
    }
    
    var blackList: [String]!
    var whiteList: [String]!
    let serversKey = "Servers"
    let whiteKey = "WhiteList"
    let blackKey = "BlackList"
    
    var servers: [UserServer]!
    var runningServers = [Socks5Server]()
    var selectedRow: Int!
    var isDirty = false
    var isWebsitesDirty = false
    var statisticsTimer: NSTimer!
    var totalSentBytes: UInt64 = 0
    var totalReceivedBytes: UInt64 = 0
    
    @IBOutlet weak var serversTableView: NSTableView!
    @IBOutlet weak var serverDetailsView: NSView!
    @IBOutlet weak var serverAddressTextField: NSTextField!
    @IBOutlet weak var serverPortTextField: NSTextField!
    @IBOutlet weak var listenAddressTextField: NSTextField!
    @IBOutlet weak var listenPortTextField: NSTextField!
    @IBOutlet weak var cipherAlgorithmComboBox: NSComboBox!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var keepConnectionCheckBox: NSButton!
    @IBOutlet weak var proxyModeComboBox: NSComboBox!
    @IBOutlet weak var connectionStatus: NSTextField!
    var blackListTextView: NSTextView!
    var whiteListTextView: NSTextView!
    @IBOutlet weak var sentBytesTextField: NSTextField!
    @IBOutlet weak var receivedBytesTextField: NSTextField!
    @IBOutlet weak var uploadSpeedTextField: NSTextField!
    @IBOutlet weak var downloadSpeedTextField: NSTextField!
    
    func startServer(userServer: UserServer) {
        let server = Socks5Server()
        server.listenAddr = userServer.listenAddr
        server.listenPort = userServer.listenPort
        server.serverAddr = userServer.address
        server.serverPort = userServer.port
        server.bypassLocal = true
        server.cipherAlgorithm = userServer.cipherAlgorithm
        server.password = userServer.password
        server.timeout = 60 * 1000
        server.tag = userServer.id
        server.proxyMode = userServer.proxyMode
        server.blackList = self.blackList
        server.whiteList = self.whiteList
        
        server.startAsync({ s in
            if (!s) {
                return
            }
            
            self.runningServers.append(server)
            self.updateStatusText(self.runningServers.count)
            
            if self.statisticsTimer == nil {
                self.statisticsTimer = NSTimer(timeInterval: 1, target: self, selector: Selector("refreshStatistics"), userInfo: nil, repeats: true)
                NSRunLoop.mainRunLoop().addTimer(self.statisticsTimer, forMode: NSRunLoopCommonModes)
            }
        })
    }
    
    func stopServerId(userServer: UserServer) {
        if let s = sinq(runningServers).firstOrNil({ s in s.tag as! Int == userServer.id }) {
            s.stop()
            runningServers.removeAtIndex(runningServers.indexOf({ ss in ss == s })!)
            updateStatusText(runningServers.count)
        }
        
        if runningServers.count == 0 {
            statisticsTimer.invalidate()
            statisticsTimer = nil
        }
    }
    
    func refreshStatistics() {
        if self.runningServers.count == 0 {
            return
        }
        
        let curSent = self.runningServers.reduce(0, combine: { n, s in n + s.sentBytes })
        let curReceived = self.runningServers.reduce(0, combine: { n, s in n + s.receivedBytes })
        
        let deltaSent = curSent - totalSentBytes
        let deltaReceived = curReceived - totalReceivedBytes
        
        totalSentBytes = curSent
        totalReceivedBytes = curReceived
        
        let (value: _, formattedValue: sent, unit: sentUnit) = StatisticsHelper.toStatisticsString(curSent)
        sentBytesTextField.stringValue = "\(sent) \(sentUnit)"
        
        let (value: _, formattedValue: received, unit: receivedUnit) = StatisticsHelper.toStatisticsString(curReceived)
        receivedBytesTextField.stringValue = "\(received) \(receivedUnit)"
        
        let (value: _, formattedValue: sentSpeed, unit: sentSpeedUnit) = StatisticsHelper.toStatisticsString(deltaSent)
        uploadSpeedTextField.stringValue = "\(sentSpeed) \(sentSpeedUnit)/s ↑"
        
        let (value: _, formattedValue: receivedSpeed, unit: receivedSpeedUnit) = StatisticsHelper.toStatisticsString(deltaReceived)
        downloadSpeedTextField.stringValue = "\(receivedSpeed) \(receivedSpeedUnit)/s ↓"
    }
    
    func saveServers(force: Bool = false) {
        if !force && !isDirty {
            return
        }
        
        isDirty = false
        let list = servers.map{ s in return [
            "address": s.address,
            "port": s.port,
            "cipherAlgorithm": s.cipherAlgorithm,
            "password": s.password,
            "keepConnection": s.keepConnection,
            "listenAddr": s.listenAddr,
            "listenPort": s.listenPort,
            "proxyMode": s.proxyMode.rawValue
        ]}
        
        SettingsHelper.saveValue(JSON(list).toString(), forKey: serversKey)
    }
    
    func saveWebsites() {
        if !isWebsitesDirty {
            return
        }
        
        SettingsHelper.saveValue(blackListTextView.string!, forKey: self.blackKey)
        SettingsHelper.saveValue(whiteListTextView.string!, forKey: self.whiteKey)
        self.blackList = blackListTextView.string!.componentsSeparatedByString("\n")
        self.whiteList = whiteListTextView.string!.componentsSeparatedByString("\n")
        
        for s in self.runningServers {
            s.blackList = self.blackList
            s.whiteList = self.whiteList
        }
        
        isWebsitesDirty = false
    }
    
    func updateStatusText(runningCount: Int) {
        dispatch_async(dispatch_get_main_queue()) {
            let color = runningCount == 0 ? NSColor.grayColor() : NSColor(red: 51.0 / 255, green: 204.0 / 255, blue: 51 / 255, alpha: 1)
            let text = runningCount == 0 ? "Stopped" : "Running: \(runningCount)"
            
            self.connectionStatus.textColor = color
            self.connectionStatus.stringValue = "◉ \(text)"
        }
    }
}


extension ViewController: NSTabViewDelegate {
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        if tabViewItem?.identifier as? String == "Websites" {
            if blackListTextView == nil {
                blackListTextView = sinq(tabViewItem!.view!.subviews).first{ v in v.identifier == "BlackListScrollView" }.subviews.first!.subviews.first as! NSTextView
                whiteListTextView = sinq(tabViewItem!.view!.subviews).first{ v in v.identifier == "WhiteListScrollView" }.subviews.first!.subviews.first as! NSTextView
            }
            
            let blackList = SettingsHelper.loadValue(defaultValue: "", forKey: self.blackKey)
            let whiteList = SettingsHelper.loadValue(defaultValue: "", forKey: self.whiteKey)
            blackListTextView.string = blackList
            whiteListTextView.string = whiteList
        }
        
        saveWebsites()
    }
}
