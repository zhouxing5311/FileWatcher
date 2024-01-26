//
//  FileWatcherSocketManager.m
//  FileWatcher
//
//  Created by 周兴 on 2022/7/20.
//

#import "FileWatcherSocketManager.h"
#import <Cocoa/Cocoa.h>
#import "GCDAsyncSocket.h"

@interface FileWatcherSocketManager ()<GCDAsyncSocketDelegate>

//监听socket
@property (nonatomic, strong) GCDAsyncSocket *listenSocket;
//这里用来保存socket，如果不保存的话，socket会被直接dealloc，然后就会出现服务器断开连接的错误
@property (nonatomic, strong) NSMutableArray<GCDAsyncSocket *> *clientSocketArray;

//心跳映射
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *heartInfo;
// 计时器
@property (nonatomic, strong) NSTimer *connectTimer;

@end

@implementation FileWatcherSocketManager

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark -- Methods
- (void)startTcpServer {
    self.listenSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *error = nil;
    //这里固定port端口为8178
    if (![self.listenSocket acceptOnPort:8178 error:&error]) {
        NSLog(@"TCP服务开启失败：%@", error);
    } else {
        NSLog(@"TCP服务开启成功");
        //开启心跳 20秒检测一次。暂时先不开启，防止debug时断点调试
//        self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:20.0 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
//         // 把定时器添加到当前运行循环,并且调为通用模式
//        [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    }
}

//心跳监测
- (void)longConnectToSocket {
    NSMutableArray *needRemoveObjects = @[].mutableCopy;
    [self.clientSocketArray enumerateObjectsUsingBlock:^(GCDAsyncSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSNumber *lastConnectNumber = self.heartInfo[pointValue(obj)];
        double lastConnectTime = lastConnectNumber.doubleValue;
        double duration = CFAbsoluteTimeGetCurrent() - lastConnectTime;
        if (duration > 20 && obj != self.listenSocket) {
            //超过20秒未连接
            [needRemoveObjects addObject:obj];
            //移除心跳数据
            [self.heartInfo removeObjectForKey:pointValue(obj)];
        }
    }];
    
    //移除超时client
    if (needRemoveObjects.count) {
        [self.clientSocketArray removeObjectsInArray:needRemoveObjects];
        [self updateConnectorInfo];
        NSLog(@"移除超时 client：%@", needRemoveObjects);
    }
}

//发送数据
- (void)sendStringToClient:(NSString *)string {
    if (!string.length) {
        return;
    }
    
    NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
    //遍历发送数据
    [self.clientSocketArray enumerateObjectsUsingBlock:^(GCDAsyncSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        //发送数据
        [obj writeData:stringData withTimeout:-1 tag:idx + 1];
    }];
}

//更新连接者信息
- (void)updateConnectorInfo {
    if (self.connectorChangedBlock) {
        NSMutableArray *deviceInfos = [NSMutableArray array];
        [self.clientSocketArray enumerateObjectsUsingBlock:^(GCDAsyncSocket * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.userData) {
                [deviceInfos addObject:obj.userData];
            }
        }];
        self.connectorChangedBlock(deviceInfos);
    }
}

#pragma mark -- GCDAsyncSocketDelegate
//当socket连接成功后，执行这个方法，然后会产生一个新的socket来处理连接，如果想要处理连接，必须retain这个socket（使其不被释放）
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    NSLog(@"开启新的链接：%@", sock);
    [self.clientSocketArray addObject:newSocket];
    //心跳数据更新
    [self.heartInfo setObject:@(CFAbsoluteTimeGetCurrent()) forKey:pointValue(newSocket)];
    //开始读取数据，timeOut为负值表示没有时间限制，读取数据完毕，执行socket:didReadData:withTag: 这个协议方法
    [newSocket readDataWithTimeout:-1 tag:self.clientSocketArray.count];
}

//读取数据完成后，执行这个方法
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"客户端传来的字符为：%@", result);
    sock.userData = result;
    [self updateConnectorInfo];
    [sock readDataWithTimeout:-1 tag:tag];
    //心跳数据更新
    double nowTime = CFAbsoluteTimeGetCurrent();
    [self.heartInfo setObject:@(nowTime) forKey:pointValue(sock)];
    NSLog(@"为 %p 更新时间：%.2f", sock, nowTime);
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"当前服务器的IP地址为：%@, 端口号：%d", host, port);
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"服务器断开了连接，错误为%@", err);
    if (sock) {
        [self.clientSocketArray removeObject:sock];
        [self updateConnectorInfo];
        NSLog(@"移除断开 client：%@", sock);
        //移除心跳数据
        [self.heartInfo removeObjectForKey:pointValue(sock)];
    }
}

#pragma mark -- Getter
- (NSMutableArray *)clientSocketArray {
    if (!_clientSocketArray) {
        _clientSocketArray = @[].mutableCopy;
    }
    return _clientSocketArray;
}

- (NSMutableDictionary<NSString *,NSNumber *> *)heartInfo {
    if (!_heartInfo) {
        _heartInfo = @{}.mutableCopy;
    }
    return _heartInfo;
}

CG_INLINE NSString * pointValue(id object) {
    return [NSString stringWithFormat:@"%p", object];
}

@end
