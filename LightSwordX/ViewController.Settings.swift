//
//  ViewController.Settings.swift
//  LightSwordX
//
//  Created by Neko on 12/29/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Cocoa
import ServiceManagement

extension ViewController {
    @IBAction func toggleLoginItem(sender: NSButton) {
        let on = sender.state == NSOnState
        let launcherIdentifier = "org.lightsword.LightSwordXHelper"
        
        SMLoginItemSetEnabled(launcherIdentifier, on)
        SettingsHelper.saveValue(on, forKey: AppKeys.LoginItem)
    }
}