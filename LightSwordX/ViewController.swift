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
        
        let login = SettingsHelper.loadValue(defaultValue: false, forKey: AppKeys.LoginItem)
        loginItemCheckBox.state = login ? NSOnState : NSOffState
    }
    
    override func awakeFromNib() {

        if self.blackList == nil {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                self.initBlackWhiteList()
            }
        }
        
        if (servers != nil && servers.count > 0) {
            return
        }
        
        let jsonStr = SettingsHelper.loadValue(defaultValue: "", forKey: AppKeys.Servers)
        
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
        let mainBundle = NSBundle.mainBundle()
        let whiteList = SettingsHelper.loadValue(defaultValue: try! NSString(contentsOfFile: mainBundle.pathForResource("white", ofType: "txt")!, encoding: NSUTF8StringEncoding), forKey: AppKeys.WhiteList)
        let blackList = SettingsHelper.loadValue(defaultValue: try! NSString(contentsOfFile: mainBundle.pathForResource("black", ofType: "txt")!, encoding: NSUTF8StringEncoding), forKey: AppKeys.BlackList)
        
        self.whiteList = whiteList.componentsSeparatedByString("\n")
        self.blackList = blackList.componentsSeparatedByString("\n")
    }
    
    @IBAction func onCloseClick(sender: NSButton) {
        view.window?.close()
        saveServers()
        saveWebsites()
        stopTimer()
    }
    
    var blackList: [String]!
    var whiteList: [String]!
    
    var servers: [UserServer]!
    var runningServers = [Socks5Server]()
    var selectedRow: Int!
    var isDirty = false
    var isWebsitesDirty = false
    var statisticsTimer: NSTimer!
    var totalSentBytes: UInt64 = 0
    var totalReceivedBytes: UInt64 = 0
    
    let ipv4Regex = Regex("^(?:[0-9]{1,3}\\.){3}[0-9]{1,3}$")
    
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
    @IBOutlet weak var loginItemCheckBox: NSButton!
    
    func startServer(userServer: UserServer) {
        let server = Socks5Server()
        server.listenAddr = userServer.listenAddr
        server.listenPort = userServer.listenPort
        server.serverAddr = userServer.address
        server.serverPort = userServer.port
        server.bypassLocal = true
        server.cipherAlgorithm = userServer.cipherAlgorithm
        server.password = userServer.password
        server.timeout = 30
        server.tag = userServer.id
        server.proxyMode = userServer.proxyMode
        server.blackList = self.blackList
        server.whiteList = self.whiteList

        server.startAsync({ s in
            if (!s) {
                let notification = NSUserNotification()
                notification.title = NSLocalizedString("Start Failed", comment: "")
                notification.informativeText = NSString(format: NSLocalizedString("Port is used", comment: "Port: %d is used"), server.listenPort) as String
                
                NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
                return
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.runningServers.append(server)
                self.updateStatusText(self.runningServers.count)
            }
        })
    }
    
    func stopServer(userServer: UserServer) {
        if let s = sinq(runningServers).firstOrNil({ s in s.tag as! Int == userServer.id }) {
            s.stop()
            runningServers.removeAtIndex(runningServers.indexOf({ ss in ss == s })!)
            updateStatusText(runningServers.count)
        }
    }
    
    func refreshStatistics() {
        if self.runningServers.count == 0 {
            return
        }
        
        var curSent = self.runningServers.reduce(0, combine: { n, s in n + s.sentBytes })
        var curReceived = self.runningServers.reduce(0, combine: { n, s in n + s.receivedBytes })
        
        if curSent < totalSentBytes {
            curSent = totalSentBytes
        }
        
        if curReceived < totalReceivedBytes {
            curReceived = totalReceivedBytes
        }
        
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
        
        SettingsHelper.saveValue(JSON(list).toString(), forKey: AppKeys.Servers)
    }
    
    func saveWebsites() {
        if !isWebsitesDirty {
            return
        }
        
        SettingsHelper.saveValue(blackListTextView.string!, forKey: AppKeys.BlackList)
        SettingsHelper.saveValue(whiteListTextView.string!, forKey: AppKeys.WhiteList)
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
            let text = runningCount == 0 ? NSLocalizedString("Stopped", comment: "") : "\(NSLocalizedString("Running", comment: "")): \(runningCount)"
            
            self.connectionStatus.textColor = color
            self.connectionStatus.stringValue = "◉ \(text)"
        }
    }
    
    func stopTimer() {
        if statisticsTimer == nil {
            return
        }
        
        statisticsTimer.invalidate()
        statisticsTimer = nil
    }
}

extension ViewController: NSTabViewDelegate {
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        let identifier = tabViewItem?.identifier as? String
        if identifier == nil {
            return
        }
        
        stopTimer()
        saveWebsites()
        
        if identifier! == "Websites" {
            if blackListTextView == nil {
                blackListTextView = sinq(tabViewItem!.view!.subviews).first{ v in v.identifier == "BlackListScrollView" }.subviews.first!.subviews.first as! NSTextView
                whiteListTextView = sinq(tabViewItem!.view!.subviews).first{ v in v.identifier == "WhiteListScrollView" }.subviews.first!.subviews.first as! NSTextView
            }
            
            let blackList = SettingsHelper.loadValue(defaultValue: try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("black", ofType: "txt")!, encoding: NSUTF8StringEncoding) as String, forKey: AppKeys.BlackList)
            let whiteList = SettingsHelper.loadValue(defaultValue: try! NSString(contentsOfFile: NSBundle.mainBundle().pathForResource("white", ofType: "txt")!, encoding: NSUTF8StringEncoding) as String, forKey: AppKeys.WhiteList)
            blackListTextView.string = blackList
            whiteListTextView.string = whiteList
            
            return
        }
        
        if identifier! == "Statistics" {
            if self.statisticsTimer == nil {
                self.statisticsTimer = NSTimer(timeInterval: 1, target: self, selector: Selector("refreshStatistics"), userInfo: nil, repeats: true)
                NSRunLoop.mainRunLoop().addTimer(self.statisticsTimer, forMode: NSRunLoopCommonModes)
                refreshStatistics()
            }
            
            return
        }
        
    }
}
