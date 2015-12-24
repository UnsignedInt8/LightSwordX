//
//  Server.swift
//  LightSwordX
//
//  Created by Neko on 12/23/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

class UserServer: Equatable {
    var address = "127.0.0.1"
    var port = 8900
    var listenAddr = "127.0.0.1"
    var listenPort = 1080
    var cipherAlgorithm = "aes-256-cfb"
    var password = "lightsword.neko"
    var keepConnection = false
    var id = 0
}

func ==(lhs: UserServer, rhs: UserServer) -> Bool {
    return lhs.address == rhs.address && lhs.port == rhs.port && lhs.listenPort == rhs.listenPort && lhs.listenAddr == rhs.listenAddr && lhs.cipherAlgorithm == rhs.cipherAlgorithm && lhs.password == rhs.password && lhs.keepConnection == rhs.keepConnection
}