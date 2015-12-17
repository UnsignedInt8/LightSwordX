//
//  Socks5Server.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

class Socks5Server {
    var serverAddr: String!
    var serverPort: Int!
    var listenAddr: String!
    var listenPort: Int!
    var cipherAlgorithm: String!
    var password: String!
    var timeout: NSTimeInterval!
    var bypassLocal: Bool!
    
    private var server: TCPServer!
    private var running = true
    private var queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    func start() -> Bool {
        server = TCPServer(addr: listenAddr, port: listenPort)
        let (success, msg) = server.listen()
        if !success {
            print(msg)
            return false
        }
        
        while running {
            if let client = server.accept() {
                dispatch_async(queue, { () -> Void in
                    let data = client.read(100)
                    if data == nil {
                        client.close()
                        return
                    }
                    
                    
                })
            }
        }
        return true
    }
    
    func stop() {
        if server == nil {
            return
        }
        
        running = false
        server.close()
        server = nil
    }
    
    private func handleHandshake(data: [UInt8]) -> (success: Bool, data: [UInt8]) {
        let methodCount = data[1]
        
        return (success: true, data: [0x5, ])
    }
}