//
//  AppDelegate.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let window = NSApplication.sharedApplication().windows.last
        window?.close()
        window?.center()
        
        // Insert code here to initialize your application
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
        
        if let button = statusItem.button {
            button.image = NSImage(named: "TrayIcon")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Window", action: Selector("openWindow:"), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Exit", action: Selector("exit:"), keyEquivalent: ""))
        
        statusItem.menu = menu
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    func openWindow(sender: NSMenuItem) {
        NSApplication.sharedApplication().windows.last!.makeKeyAndOrderFront(nil)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }
    
    func exit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
}

