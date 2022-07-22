//
//  FileWatcherSocketManager.h
//  FileWatcher
//
//  Created by 周兴 on 2022/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FileWatcherConnectorChanged)(NSArray<NSString *> *connectors);

@interface FileWatcherSocketManager : NSObject

@property (nonatomic, copy) FileWatcherConnectorChanged connectorChangedBlock;

//开启socket
- (void)startTcpServer;
//发送数据
- (void)sendStringToClient:(NSString *)string;

@end

NS_ASSUME_NONNULL_END
