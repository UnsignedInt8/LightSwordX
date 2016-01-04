//
//  Socks5Helper.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation
import SINQ

class Socks5Helper {
    static func refineDestination(rawData: [UInt8]) -> (cmd: REQUEST_CMD, addr: String, port: Int, headerSize: Int) {
        let cmd = REQUEST_CMD(rawValue: rawData[1])!
        let atyp = rawData[3]
        var addr = ""
        var dnLength: UInt8 = 0

        switch (atyp) {
        case ATYP.DN.rawValue:
            dnLength = rawData[4]
            let data = sinq(rawData).skip(5).take(Int(dnLength)).toArray()
            addr = NSString(bytes: data, length: data.count, encoding: NSUTF8StringEncoding) as! String
            break
            
        case ATYP.IPV4.rawValue:
            dnLength = 4
            addr = sinq(rawData).skip(4).take(4).aggregate("", combine: { (c: String, n: UInt8) in c.characters.count > 1 ? c + String(format: ".%d", n) : String(format: "%d.%d", c, n)})
            break
            
        case ATYP.IPV6.rawValue:
            dnLength = 16
            let bytes = sinq(rawData).skip(4).take(16).toArray()
            addr = bytes.reduce("", combine: { (s: String, n: UInt8) -> String in
                return ""
            })
            
            break
            
        default:
            break
        }
        
        let headerSize = Int(4 + (atyp == ATYP.DN.rawValue ? 1 : 0) + dnLength + 2)
        let littleEndian = [rawData[headerSize - 2], rawData[headerSize - 1]]
        var port = UnsafePointer<UInt16>(littleEndian).memory
        port = port.bigEndian
        return ( cmd, addr, Int(port), headerSize )
    }
}