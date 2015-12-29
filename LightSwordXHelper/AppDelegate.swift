//
//  AppDelegate.swift
//  LightSwordXHelper
//
//  Created by Neko on 12/28/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let path = NSBundle.mainBundle().bundlePath as NSString
        var components = path.pathComponents
        components.removeLast()
        components.removeLast()
        components.removeLast()
        components.append("MacOS")
        components.append("LightSwordX")
        
        NSWorkspace.sharedWorkspace().launchApplication(NSString.pathWithComponents(components))
        NSApp.terminate(nil)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }


}

