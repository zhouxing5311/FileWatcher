//
//  KZServerManager.m
//  PerformanceMonitoring
//
//  Created by Yaping Liu on 2018/5/18.
//  Copyright © 2018年 Yaping Liu. All rights reserved.
//

#import "KZServerManager.h"
#import "HTTPServer.h"
#import "KZHTTPConnection.h"
#import <ifaddrs.h>
#import <arpa/inet.h>

@interface KZServerManager ()

@property (nonatomic, strong) HTTPServer *customServer;

@property (nonatomic, assign, readwrite) BOOL isRunning;

@end

@implementation KZServerManager

+ (instancetype)shareServerManager {
    static KZServerManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[KZServerManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.customServer = [[HTTPServer alloc] init];
        // Tell the server to broadcast its presence via Bonjour.
        // This allows browsers such as Safari to automatically discover our service.
//        [self.customServer setType:@"_http._tcp."];
        [self.customServer setPort:12345];
        [self.customServer  setConnectionClass:[KZHTTPConnection class]];
        self.isRunning = NO;

    }
    return self;
}

- (void)customPort:(UInt16)port {
    [self.customServer setPort:port];
}

- (NSError *_Nullable)startServer {
    if (self.isRunning) {
        return [NSError errorWithDomain:@"error"
                                   code:-1
                               userInfo:@{NSLocalizedDescriptionKey:@"服务开启中"}];
    }
    
    NSError *error = nil;
    if ([self.customServer start:&error]) {
        self.isRunning = YES;
    } else {
        NSLog(@"Starting HTTP Server error: %@", error);
    }
    return error;
}

- (void)stopServer {
    if (!self.isRunning) return;
    [self.customServer stop];
    self.isRunning = NO;
}

- (NSString *)localAddress {

    NSString *address = [self deviceIPAddress];
    UInt16 port = [self.customServer listeningPort];
    return [NSString stringWithFormat:@"%@:%d",address,port];
}

- (NSString *)deviceIPAddress {
    
    return  [self getIPAddress] ? : @"0.0.0.0";
}

- (NSString *)getIPAddress
{
    NSString *address = nil;
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while (temp_addr && !address) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] containsString:@"en"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    // Free memory
    freeifaddrs(interfaces);
    
    return address;
}


@end
