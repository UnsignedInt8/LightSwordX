//
//  TCPSocket.c
//  LightSwordX
//
//  Created by Neko on 1/9/16.
//  Copyright © 2016 Neko. All rights reserved.
//

#include <stdio.h>
#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <sys/types.h>
#include <netinet/in.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <dirent.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <sys/select.h>

void tcpsocket_set_block(int socket, int on) {
    int flags = fcntl(socket, F_GETFL, 0);
    
    if (on == 0) {
        fcntl(socket, F_SETFL, flags | O_NONBLOCK);
    } else {
        flags &= ~ O_NONBLOCK;
        fcntl(socket, F_SETFL, flags);
    }
}

int tcpsocket_connect(const char* host, int port, int timeout) {
    
    struct addrinfo hints, *addrs, *p;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    
    int s = getaddrinfo(host, NULL, NULL, &addrs);
    if (s != 0) {
        fprintf(stderr, "getaddrinfo: %s\n", gai_strerror(s));
        return -1;
    }

    int socketfd = -1;
    
    for (p = addrs; p != NULL; p = p->ai_next) {
    
        if ((socketfd = socket(addrs->ai_family, addrs->ai_socktype, addrs->ai_protocol) < 0)) {
            socketfd = -1;
            continue;
        }
        
        tcpsocket_set_block(socketfd, 0); // Set non-block socket
        connect(socketfd, addrs->ai_addr, addrs->ai_addrlen);
        
        fd_set fdset;
        FD_ZERO(&fdset);
        FD_SET(socketfd, &fdset);
        
        struct timeval tv;
        tv.tv_sec = timeout;
        tv.tv_usec = 0;
        
        int retval = select(socketfd + 1, NULL, &fdset, NULL, &tv);
        if (retval <= 0) {
            close(socketfd); // Error or Timeout
            socketfd = -1;
            continue;
        }
        
        int error = 0;
        int errorlen = sizeof(error);
        
        getsockopt(socketfd, SOL_SOCKET, SO_ERROR, &error, (socklen_t *)&errorlen);
        if (error != 0) {
            fprintf(stderr, "failed to connect: %s\n", gai_strerror(error));
            close(socketfd); // Failed to connect
            socketfd = -1;
            continue;
        }
        
        tcpsocket_set_block(socketfd, 1);
        int set = 1;
        setsockopt(socketfd, SOL_SOCKET, SO_NOSIGPIPE, (void *)&set, sizeof(int));
        
        break;
    }
    
    freeaddrinfo(addrs);
    
    return socketfd;
}

int tcpsocket_close(int socketfd) {
    return close(socketfd);
}

int tcpsocket_pull(int socketfd, char* data, int len, int timeout) {
    if (timeout > 0) {
        fd_set fdset;
        FD_ZERO(&fdset);
        FD_SET(socketfd, &fdset);
        
        struct timeval tv;
        tv.tv_usec = 0;
        tv.tv_sec = timeout;
        
        int ret = select(socketfd + 1, &fdset, NULL, NULL, &tv);
        if (ret <= 0) {
            return ret;
        }
    }
    
    return (int)read(socketfd, data, len);
}

int tcpsocket_send(int socketfd, const char* data, int len) {
    int byteswrote = 0;
    while (len - byteswrote > 0) {
        int wrotelen = (int)write(socketfd, data + byteswrote, len - byteswrote);
        if (wrotelen < 0) {
            return -1;
        }
        
        byteswrote += wrotelen;
    }
    
    return byteswrote;
}

int tcpsocket_accept(int socketfd, char* remoteip, int* remoteport) {
    char clienthost[NI_MAXHOST];
    char clientservice[NI_MAXSERV];
    
    struct sockaddr_storage clientaddr;
    socklen_t addrlen = sizeof(clientaddr);
    
    int connfd = accept(socketfd, (struct sockaddr *)&clientaddr, &addrlen);
    if (getnameinfo((struct sockaddr *)&clientaddr, addrlen, clienthost, NI_MAXHOST, clientservice, NI_MAXSERV, NI_NUMERICHOST)) {
        fprintf(stderr, "can not resolve name");
    } else {
        if (clientaddr.ss_family == AF_INET) {
            struct sockaddr_in* ipv4 = (struct sockaddr_in *)&clientaddr;
            char* clientip = inet_ntoa(ipv4->sin_addr);
            memcpy(remoteip, clientip, strlen(clientip));
            *remoteport = ipv4->sin_port;
        } else if (clientaddr.ss_family == AF_INET6) {
            struct sockaddr_in6* ipv6 = (struct sockaddr_in6 *)&clientaddr;
            char clientip[INET6_ADDRSTRLEN];
            inet_ntop(AF_INET6, &(ipv6->sin6_addr), clientip, INET6_ADDRSTRLEN);
            memcpy(remoteip, clientip, strlen(clientip));
            *remoteport = ipv6->sin6_port;
        }
    }
    
    return connfd > 0 ? connfd : -1;
}

int tcpsocket_listen(const char* addr, int port) {
    int socketfd = -1;
    struct addrinfo hints, *servinfo, *p;
    int rv;
    
    memset(&hints, 0, sizeof(hints));
    hints.ai_family = AF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_flags = AI_PASSIVE; // Used for self IP
    
    char portnumber[6];
    memset(portnumber, 0, 6);
    snprintf(portnumber, 6, "%d", port);
    
    if ((rv = getaddrinfo(NULL, portnumber, &hints, &servinfo)) != 0) {
        fprintf(stderr, "%s", gai_strerror(rv));
        return -1;
    }
    
    for (p = servinfo; p != NULL; p = p->ai_next) {
        if ((socketfd = socket(p->ai_family, p->ai_socktype, p->ai_protocol) == -1)) {
            continue;
        }
        
        if (bind(socketfd, p->ai_addr, p->ai_addrlen) != 0) {
            close(socketfd);
            continue;
        }
        
        if (listen(socketfd, 256) == 0) {
            break;
        }
    }
    
    freeaddrinfo(servinfo);
    
    return socketfd;
}

