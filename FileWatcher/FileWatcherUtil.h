//
//  FileWatcherUtil.h
//  FileWatcher
//
//  Created by 周兴 on 2022/7/22.
//

#import <Foundation/Foundation.h>
#import "SEResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface FileWatcherUtil : NSObject

+ (SEResult *)runWithCmd:(NSString *)format,...;

@end

NS_ASSUME_NONNULL_END
