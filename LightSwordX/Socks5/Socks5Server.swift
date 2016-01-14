//
//  Socks5Server.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import SINQ
import Foundation
import CryptoSwift

enum ProxyMode: Int {
    case GLOBAL = 0
    case BLACK = 1
    case WHITE = 2
}

class Socks5Server {
    var serverAddr: String!
    var serverPort: Int!
    var listenAddr: String!
    var listenPort: Int!
    var cipherAlgorithm: String!
    var password: String!
    var timeout: Int!
    var bypassLocal: Bool!
    var tag: AnyObject?
    var blackList: [String]!
    var whiteList: [String]!
    var proxyMode = ProxyMode.GLOBAL
    
    private(set) var sentBytes: UInt64 = 0
    private(set) var receivedBytes: UInt64 = 0
    
    private var server: TCPServer6!
    private var running = true
    private var queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    private let localAreas = ["10.", "192.168.", "localhost", "127.0.0.1", "172.16.", "::1", "169.254.0.0"]
    private let localServers = ["127.0.0.1", "localhost", "::1"]
    private let bufferSize = 1520
    
    func startAsync(callback: (success: Bool) -> Void) {
        dispatch_async(queue) {
            self.startSync(callback)
        }
    }
    
    func startSync(callback: (success: Bool) -> Void) {
        running = true
        
        server = TCPServer6(addr: listenAddr, port: listenPort)
        let (success, msg) = server.listen()
        if !success {
            running = false
            callback(success: false)
            print(msg)
            return
        }

        callback(success: true)
        while running {
            if let client = server.accept() {
                dispatch_async(queue, { () -> Void in
                    client.timeout = self.timeout
                    
                    let (data: hello, _) = client.read(768)
                    guard hello != nil else {
                        client.close()
                        return
                    }
                    
                    let (success, reply) = self.handleHandshake(hello!)
                    client.send(data: reply)
                    
                    if !success {
                        client.close()
                        return
                    }
                    
                    let (data, _) = client.read(self.bufferSize)
                    guard data != nil else {
                        client.close()
                        return
                    }
                    
                    let request: (cmd: REQUEST_CMD, addr: String, port: Int, headerSize: Int)! = Socks5Helper.refineDestination(data!)
                    if request == nil {
                        client.close()
                        return
                    }
                    
                    let connectLocal = sinq(self.localServers).any({ s in self.serverAddr.containsString(s)}) || self.bypassLocal.boolValue && sinq(self.localAreas).any({ s in request.addr.containsString(s)})
                    
                    switch(request.cmd) {
                    case .BIND:
                        break
                    case .CONNECT:
                        if (connectLocal) {
                            self.connectToTarget(request.addr, destPort: request.port, requestBuf: data!, client: client)
                        } else {
                            self.connectToServer(request.addr, destPort: request.port, requestBuf: data!, client: client)
                        }
                        
                        break
                    case .UDP_ASSOCIATE:
                        break
                    }
                })
            }
        }
        
    }
    
    func stop() {
        running = false
        
        if server == nil {
            return
        }
        
        server.close()
        server = nil
    }
    
    private func handleHandshake(data: [UInt8]) -> (success: Bool, reply: [UInt8]) {
        if data.count < 2 {
            return (success: false, reply: [0x5, Authentication.NONE.rawValue])
        }
        
        let methodCount = data[1]
        let code = sinq(data).skip(2).take(Int(methodCount)).contains(Authentication.NOAUTH.rawValue) ? Authentication.NOAUTH : Authentication.NONE
        
        return (success: true, reply: [0x5, code.rawValue])
    }
    
    private func connectToTarget(destAddr: String, destPort: Int, requestBuf: [UInt8], client: TCPClient6) {
        let transitSocket = TCPClient6(addr: destAddr, port: destPort)
        let (success, msg) = transitSocket.connect(timeout: timeout)
        if !success {
            client.close()
            print(msg, destAddr)
            return
        }
        
        print("connected:", destAddr)
        
        var reply = requestBuf.map { n in return n }
        reply[0] = 0x05
        reply[1] = 0x00
        
        client.send(data: reply)
        
        dispatch_async(queue, { () -> Void in
            self.sentBytes += self.exchangeSocket(client, writeSocket: transitSocket)
        })
        
        dispatch_async(queue, { () -> Void in
            self.receivedBytes += self.exchangeSocket(transitSocket, writeSocket: client)
        })
    }
    
    private func exchangeSocket(readSocket: TCPClient6, writeSocket: TCPClient6, secret: UInt8? = nil) -> UInt64 {
        var bytes: UInt64 = 0
        var retry = 0
        var readSize = self.bufferSize
        var accidentalFailure = 0
        
        while true {
            let (data, errno) = readSocket.read(readSize)
            
            guard data != nil else {
                if errno == 0 {
                    
                    if accidentalFailure < 2 {
                        accidentalFailure++
                        continue
                    }
                    
                    readSocket.close()
                    writeSocket.close()
                    break
                }
                
                switch errno {
                case -1:
                    readSocket.close()
                    writeSocket.close()
                    return bytes
                    
                case EAGAIN:
                    print("try again")
                    continue
                    
                case EINVAL:
                    print("EINVAL")
                    fallthrough
                case EFAULT:
                    print("EFAULT")
                    readSize += readSize
                    break
                    
                case EBADF:
                    print("EBADF")
                    break
                case EIO:
                    print("EIO")
                    break
                case EINTR:
                    print("EINTR")
                    break
                default:
                    break
                }
                
                print("error:", errno)
                
                if retry < 7 {
                    retry++
                    print("retry", retry)
                    continue
                }
                
                readSocket.close()
                writeSocket.close()
                break
            }
            
            if retry > 0 {
                print("recovery from failure -", retry)
            }
            
            writeSocket.send(data: secret != nil ? data!.map{ n in n ^ secret! } : data!)
            bytes += UInt64(data!.count)
            retry = 0
        }
        
        return bytes
    }
    
    private func connectToServer(destAddr: String, destPort: Int, requestBuf: [UInt8], client: TCPClient6) {
        switch proxyMode {
        case .BLACK:
            if blackList != nil && sinq(blackList).any({ l in destAddr.endsWith(l) }) {
                break
            }
            connectToTarget(destAddr, destPort: destPort, requestBuf: requestBuf, client: client)
            return
            
        case .WHITE:
            if whiteList != nil && sinq(whiteList).any({ l in destAddr.endsWith(l) }) {
                connectToTarget(destAddr, destPort: destPort, requestBuf: requestBuf, client: client)
                return
            }
            break
            
        case .GLOBAL:
            break
        }

        let proxySocket = TCPClient6(addr: serverAddr, port: serverPort)
        let (success, msg) = proxySocket.connect(timeout: timeout)
        if !success {
            client.close()
            print(msg)
            return
        }
        
        let (cipher, iv) = Crypto.createCipher(cipherAlgorithm, password: password)
        let pl = UInt8(arc4random() % 256)
        let pa = AES.randomIV(Int(pl))
        let et = try! cipher.encrypt(sinq([VPN_TYPE.OSXCL5.rawValue, pl]).concat(pa).concat(requestBuf).toArray(), padding: nil)
        
        proxySocket.send(data: sinq(iv).concat(et).toArray())
        
        let (data, _) = proxySocket.read(1024)
        if data == nil || data?.count < iv.count {
            client.close()
            proxySocket.close()
            return
        }
        
        let riv = sinq(data!).take(iv.count).toArray()
        let (cipher: decipher, _) = Crypto.createCipher(cipherAlgorithm, password: password, iv: riv)
        let rlBuf = sinq(data!).skip(iv.count).toArray()
        var reBuf = try! decipher.decrypt(rlBuf, padding: nil)
        let paddingSize = reBuf[0]
        
        reBuf = sinq(reBuf).skip(1 + Int(paddingSize)).toArray()
        client.send(data: reBuf)
        
        print("connected:", destAddr)
        
        dispatch_async(queue, { () -> Void in
            self.sentBytes += self.exchangeSocket(client, writeSocket: proxySocket, secret: pl)
        })
        
        dispatch_async(queue, { () -> Void in
            self.receivedBytes += self.exchangeSocket(proxySocket, writeSocket: client, secret: paddingSize)
        })
    }
    
}

extension Socks5Server: Equatable {
    
}

func ==(lhs: Socks5Server, rhs: Socks5Server) -> Bool {
    return lhs.serverAddr == rhs.serverAddr && lhs.serverPort == rhs.serverPort && lhs.listenAddr == rhs.listenAddr && lhs.listenPort == rhs.listenPort && lhs.cipherAlgorithm == rhs.cipherAlgorithm && lhs.password == rhs.password
}