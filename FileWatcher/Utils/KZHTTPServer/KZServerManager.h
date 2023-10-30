//
//  KZServerManager.h
//  PerformanceMonitoring
//
//  Created by Yaping Liu on 2018/5/18.
//  Copyright © 2018年 Yaping Liu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KZServerManager : NSObject

+ (instancetype)shareServerManager;

@property (nonatomic, assign, readonly) BOOL isRunning;

- (NSError *_Nullable)startServer;

- (void)stopServer;

- (void)customPort:(UInt16)port;

- (NSString *)localAddress;

@end
