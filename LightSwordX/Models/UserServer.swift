//
//  Server.swift
//  LightSwordX
//
//  Created by Neko on 12/23/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

public class UserServer {
    var address = "127.0.0.1"
    var port = 8900
    var listenAddr = "127.0.0.1"
    var listenPort = 1080
    var cipherAlgorithm = "aes-256-cfb"
    var password = "lightsword.neko"
    var keepConnection = false
}