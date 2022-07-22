//
//  FileWatcherManager.h
//  FileWatcher
//
//  Created by 周兴 on 2022/7/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^FileModifyBlock)(NSString *fileName);

@interface FileWatcherManager : NSObject

+ (instancetype)sharedInstance;

- (void)startWatchWithFilePaths:(NSArray<NSString *> *)filePaths
                    modifyBlock:(FileModifyBlock)modifyBlock;
- (void)stopWatch;

@end

NS_ASSUME_NONNULL_END
