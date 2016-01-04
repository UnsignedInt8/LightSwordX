//
//  Socks5Constants.swift
//  LightSwordX
//
//  Created by Neko on 12/17/15.
//  Copyright © 2015 Neko. All rights reserved.
//

import Foundation

enum Authentication: UInt8 {
    case NOAUTH = 0x00
    case GSSAPI = 0x01
    case USERPASS = 0x02
    case NONE = 0xFF
}

enum REQUEST_CMD: UInt8 {
    case CONNECT = 0x01
    case BIND = 0x02
    case UDP_ASSOCIATE = 0x03
}

enum ATYP: UInt8 {
    case IPV4 = 0x01
    case DN = 0x03
    case IPV6 = 0x04
}

enum REPLY_CODE: UInt8 {
    case SUCCESS = 0x00
    case SOCKS_SERVER_FAILURE = 0x01
    case CONNECTION_NOT_ALLOWED = 0x02
    case NETWORK_UNREACHABLE = 0x03
    case HOST_UNREACHABLE = 0x04
    case CONNECTION_REFUSED = 0x05
    case TTL_EXPIRED = 0x06
    case CMD_NOT_SUPPORTED = 0x07
    case ADDR_TYPE_NOT_SUPPORTED = 0x08
}

enum SOCKS_VER: UInt8 {
    case V5 = 0x05
}
