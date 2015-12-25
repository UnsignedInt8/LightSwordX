//
//  ViewController.Websites.swift
//  LightSwordX
//
//  Created by Neko on 12/25/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

extension ViewController: NSTextDelegate {
    func textDidChange(notification: NSNotification) {
        isWebsitesDirty = true
    }
}