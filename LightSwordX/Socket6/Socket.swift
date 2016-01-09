//
//  Socket.swift
//  LightSwordX
//
//  Created by Neko on 1/9/16.
//  Copyright © 2016 Neko. All rights reserved.
//

import Foundation

class Socket {
    var addr: String
    var port: Int
    var fd: Int32?
    
    init() {
        self.addr = ""
        self.port = 0
    }
    
    init(addr a: String, port p: Int) {
        self.addr = a
        self.port = p
    }
}