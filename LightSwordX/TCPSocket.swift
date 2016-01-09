//
//  TCPSocket.swift
//  LightSwordX
//
//  Created by Neko on 1/9/16.
//  Copyright © 2016 Neko. All rights reserved.
//

import Foundation

@asmname("tcpsocket_connect") func c_tcpsocket_connect(host:UnsafePointer<Int8>, port:Int32, timeout:Int32) -> Int32
@asmname("tcpsocket_close") func c_tcpsocket_close(fd:Int32) -> Int32
@asmname("tcpsocket_send") func c_tcpsocket_send(fd:Int32, buff:UnsafePointer<UInt8>, len:Int32) -> Int32
@asmname("tcpsocket_pull") func c_tcpsocket_pull(fd:Int32, buff:UnsafePointer<UInt8>, len:Int32, timeout:Int32) -> Int32
@asmname("tcpsocket_listen") func c_tcpsocket_listen(addr:UnsafePointer<Int8>, port:Int32)->Int32
@asmname("tcpsocket_accept") func c_tcpsocket_accept(socketfd:Int32, ip:UnsafePointer<Int8>, port:UnsafePointer<Int32>) -> Int32

class TCPClient6: Socket {
    func connect(timeout t: Int) -> (Bool, String) {
        let r = c_tcpsocket_connect(self.addr, port: Int32(self.port), timeout: Int32(t))
        
        if r > 0 {
            self.fd = r
            return (true, "connceted")
        } else {
            switch r {
            case -1:
                return (false, "query server fail")
            default:
                return (false, "unknow err")
            }
        }
    }
    
    func close() -> (Bool, String) {
        guard let fd = self.fd else {
            return (false, "socket not open")
        }
        
        c_tcpsocket_close(fd)
        self.fd = nil
        return (true, "closed")
    }
    
    func send(data d: [UInt8]) -> (Bool, String) {
        guard let fd = self.fd else {
            return (false, "socket not open")
        }
        
        let sent = c_tcpsocket_send(fd, buff: d, len: Int32(d.count))
        if Int(sent) == d.count {
            return (true, "succcess")
        } else {
            return (false, "error")
        }
    }
    
    func send(str s: String) -> (Bool, String) {
        guard let fd = self.fd else {
            return (false, "socket not open")
        }
        
        let sent = c_tcpsocket_send(fd, buff: s, len: Int32(strlen(s)))
        if sent == Int32(strlen(s)) {
            return (true, "success")
        }
        
        return (false, "error")
    }
    
    func send(data d: NSData) -> (Bool, String) {
        guard let fd = self.fd else {
            return (false, "socket not open")
        }
        
        var buf = [UInt8](count: d.length, repeatedValue: 0)
        d.getBytes(&buf, length: d.length)
        
        let sent = c_tcpsocket_send(fd, buff: buf, len: Int32(d.length))
        if sent == Int32(d.length) {
            return (true, "success")
        }
        
        return (false, "error")
    }
    
    func read(exceptLength: Int, timeout: Int = -1) -> [UInt8]? {
        guard let fd = self.fd else {
            return nil
        }
        
        var buf = [UInt8](count: exceptLength, repeatedValue: 0)
        let read = c_tcpsocket_pull(fd, buff: buf, len: Int32(exceptLength), timeout: Int32(timeout))
        if read <= 0 {
            return nil
        }
        
        return Array(buf[0...Int(read - 1)])
    }
}

class TCPServer6: Socket {
    
    func listen() -> (Bool, String) {
        let fd = c_tcpsocket_listen(self.addr, port: Int32(self.port))
        if fd > 0 {
            self.fd = fd;
            return (true, "listening")
        }
        
        return (false, "Failed to listen")
    }
    
    func accept() -> TCPClient6? {
        guard let fd = self.fd else {
            return nil
        }
        
        var buf = [Int8](count: 16, repeatedValue: 0)
        var port: Int32 = 0
        let clientfd = c_tcpsocket_accept(fd, ip: &buf, port: &port)
        if clientfd < 0 {
            return nil
        }
        
        let client = TCPClient6()
        client.fd = clientfd
        client.port = Int(port)
        if let addr = String(CString: buf, encoding: NSUTF8StringEncoding) {
            client.addr = addr
        }
        
        return client
    }
    
    func close() -> (Bool, String) {
        guard let fd = self.fd else {
            return (false, "socket not open")
        }
        
        c_tcpsocket_close(fd)
        self.fd = nil
        return (true, "closed")
    }
}