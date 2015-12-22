//: Playground - noun: a place where people can play

import Cocoa

let bytes1: [UInt8] = [0x1, 0x2, 0x3, 0x4]
let xr = UInt8(arc4random() % 256)
let bytesXor = bytes1.map({ n in n ^ xr })
let bytesRaw = bytesXor.map({ n in n ^ xr })
assert(bytesRaw[0] == bytes1[0])