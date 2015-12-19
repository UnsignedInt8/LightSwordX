//
//  Socks5Server.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation
import SINQ

class Socks5Server {
    var serverAddr: String!
    var serverPort: Int!
    var listenAddr: String!
    var listenPort: Int!
    var cipherAlgorithm: String!
    var password: String!
    var timeout: Int!
    var bypassLocal: Bool!
    
    private var server: TCPServer!
    private var running = true
    private var queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    private let localAreas = ["10.", "192.168.", "localhost", "127.0.0.1", "172.16.", "::1", "169.254.0.0"]
    
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
                    var data = client.read(100)
                    if data == nil {
                        client.close()
                        return
                    }
                    
                    let (success, reply) = self.handleHandshake(data!)
                    client.send(data: reply)
                    if !success {
                        client.close()
                        return
                    }
                    
                    data = client.read(100)
                    if data == nil {
                        client.close()
                        return
                    }
                    
                    let request = Socks5Helper.refineDestination(data!)
                    let connectLocal = self.bypassLocal.boolValue && sinq(self.localAreas).any({ s in request.addr.containsString(s)})
                    
                    switch(request.cmd) {
                    case .BIND:
                        break
                    case .CONNECT:
                        if (connectLocal) {
                            self.connectToTarget(request.addr, destPort: request.port, requestBuf: data!, client: client)
                        } else {
                            self.connectToServer(request.addr, destPort: request.port, client: client)
                        }
                        
                        break
                    case .UDP_ASSOCIATE:
                        break
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
    
    private func handleHandshake(data: [UInt8]) -> (success: Bool, reply: [UInt8]) {
        let methodCount = data[1]
        let code = sinq(data).skip(2).take(Int(methodCount)).contains(Authentication.NOAUTH.rawValue) ? Authentication.NOAUTH : Authentication.NONE
        
        return (success: true, reply: [0x5, code.rawValue])
    }
    
    private func connectToTarget(destAddr: String, destPort: Int, requestBuf: [UInt8], client: TCPClient) {
        let transitSocket = TCPClient(addr: destAddr, port: destPort)
        let (success, msg) = transitSocket.connect(timeout: timeout)
        if !success {
            client.close()
            print(msg)
            return
        }
        
        print("connected:", destAddr)
        
        var reply = requestBuf.map { n in return n }
        reply[0] = 0x05
        reply[1] = 0x00
        
        client.send(data: reply)
        
        dispatch_async(queue, { () -> Void in
            while true {
                if let data = client.read(1500, timeout: self.timeout) {
                    transitSocket.send(data: data)
                } else {
                    client.close()
                    transitSocket.close()
                    print("closed from client")
                    break
                }
            }
        })
        
        dispatch_async(queue, { () -> Void in
            while true {
                if let data = transitSocket.read(1500, timeout: self.timeout) {
                    client.send(data: data)
                } else {
                    client.close()
                    transitSocket.close()
                    print("closed from proxy")
                    break
                }
            }
        })
    }
    
    private func connectToServer(destAddr: String, destPort: Int, client: TCPClient) {
        let proxySocket = TCPClient(addr: serverAddr, port: serverPort)
        let (success, msg) = proxySocket.connect(timeout: timeout)
        if !success {
            client.close()
            print(msg)
            return
        }
        
        
    }
}