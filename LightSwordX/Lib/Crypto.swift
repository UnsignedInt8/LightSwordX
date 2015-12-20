//
//  Crypto.swift
//  LightSwordX
//
//  Created by Neko on 12/19/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import SINQ
import Foundation
import CryptoSwift

class Crypto {

    static let SupportedCiphers = [
        "aes-256-cfb": (info: [32, 16], blockMode: CipherBlockMode.CFB),
        "aes-192-cfb": (info: [24, 16], blockMode: CipherBlockMode.CFB),
        "aes-128-cfb": (info: [16, 16], blockMode: CipherBlockMode.CFB)
    ]
    
    static func createCipher(algorithm: String, password: String, iv: [UInt8]? = nil) -> (cipher: AES, iv: [UInt8]) {
        var tuple: (info: [Int], blockMode: CipherBlockMode)! = SupportedCiphers[algorithm.lowercaseString]
        if tuple == nil {
            tuple = (info: [32, 16], blockMode: CipherBlockMode.CFB)
        }
        
        var key = [UInt8](password.utf8)
        if key.count > tuple.info[0] {
            key = sinq(key).take(tuple.info[0]).toArray()
        } else {
            let longPw = String(count: (tuple.info[0] / password.length) + 1, byRepeatingString: password)!
            key = [UInt8](longPw.utf8)
            key = sinq(key).take(tuple.info[0]).toArray()
        }
        
        var civ: [UInt8]! = iv
        if civ == nil {
            civ = AES.randomIV(tuple.info[1])
        }
        
        let cipher = try! AES(key: key, iv: civ, blockMode: tuple.blockMode)
        return (cipher: cipher, iv: civ)
    }
}

