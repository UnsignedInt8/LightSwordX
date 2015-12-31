//
//  AppDelegate.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        if SettingsHelper.loadValue(defaultValue: "", forKey: "Servers").length > 0 {
            NSApplication.sharedApplication().windows.last!.close()
        }
        
        if let button = statusItem.button {
            button.image = NSImage(named: "TrayIcon")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: NSLocalizedString("Preferences", comment: ""), action: Selector("openPreferences:"), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: NSLocalizedString("Quit", comment: ""), action: Selector("quit:"), keyEquivalent: ""))
        
        statusItem.menu = menu
        
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, shouldPresentNotification notification: NSUserNotification) -> Bool {
        return true
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }

    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(NSSquareStatusItemLength)
    
    func openPreferences(sender: NSMenuItem) {
        NSApplication.sharedApplication().windows.last!.makeKeyAndOrderFront(nil)
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
    }
    
    func quit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(self)
    }
}

