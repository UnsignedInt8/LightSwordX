//: Playground - noun: a place where people can play

import Cocoa

var status: Int32 = 0

// Protocol configuration

var hints = addrinfo(
    ai_flags: AI_PASSIVE,       // Assign the address of my local host to the socket structures
    ai_family: AF_UNSPEC,       // Either IPv4 or IPv6
    ai_socktype: SOCK_STREAM,   // TCP
    ai_protocol: 0,
    ai_addrlen: 0,
    ai_canonname: nil,
    ai_addr: nil,
    ai_next: nil)


// For the result from the getaddrinfo

var servinfo = UnsafeMutablePointer<addrinfo>.init()


// Get the info we need to create our socket descriptor

status = getaddrinfo("ip.cn", "", &hints, &servinfo)

print(status)

print(servinfo.memory.ai_addr)