//
//  PYSeverUtil.h
//  FileWatcher
//
//  Created by 周兴 on 2023/10/27.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PYSeverUtil : NSObject

/// 开启服务（返回错误描述）
/// - Parameter port: 端口号（不传系统会随机分配一个）
/// - Parameter path: 服务开启路径
+ (NSString *_Nullable)startSever:(NSInteger)port path:(NSString *)path;

/// 关闭服务（返回错误描述）
/// - Parameter port: 端口号
+ (NSString *_Nullable)closeSever:(NSInteger)port;

@end

NS_ASSUME_NONNULL_END
