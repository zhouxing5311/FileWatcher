//
//  FileWatcherManager.m
//  FileWatcher
//
//  Created by 周兴 on 2022/7/20.
//

#import "FileWatcherManager.h"
#import <CoreServices/CoreServices.h>

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]);

@interface FileWatcherManager ()

@property(nonatomic) NSInteger syncEventID;
@property(nonatomic, assign) FSEventStreamRef syncEventStream;
@property(nonatomic, copy) FileModifyBlock modifyBlock;

@end

@implementation FileWatcherManager

+ (instancetype)sharedInstance {
    static FileWatcherManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (void)startWatchWithFilePaths:(NSArray<NSString *> *)filePaths
                    modifyBlock:(FileModifyBlock)modifyBlock {
    self.modifyBlock = [modifyBlock copy];
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
    }
    
//    NSArray *paths = @[@"/Users/yww/Desktop/test"];// 这里填入需要监控的文件夹
    FSEventStreamContext context;
    context.info = (__bridge void * _Nullable)(self);
    context.version = 0;
    context.retain = NULL;
    context.release = NULL;
    context.copyDescription = NULL;
    self.syncEventStream = FSEventStreamCreate(NULL, &fsevents_callback, &context, (__bridge CFArrayRef _Nonnull)(filePaths), self.syncEventID, 1, kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes);
    FSEventStreamScheduleWithRunLoop(self.syncEventStream, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    FSEventStreamStart(self.syncEventStream);
}

- (void)stopWatch {
    if(self.syncEventStream) {
        FSEventStreamStop(self.syncEventStream);
        FSEventStreamInvalidate(self.syncEventStream);
        FSEventStreamRelease(self.syncEventStream);
        self.syncEventStream = NULL;
    }
}

- (void)modifyFileName:(NSString *)fileName {
    !self.modifyBlock ?: self.modifyBlock(fileName);
}

#pragma mark - private method
-(void)updateEventID {
    self.syncEventID = FSEventStreamGetLatestEventId(self.syncEventStream);
}

#pragma mark - setter
-(void)setSyncEventID:(NSInteger)syncEventID{
    [[NSUserDefaults standardUserDefaults] setInteger:syncEventID forKey:@"SyncEventID"];
}
-(NSInteger)syncEventID {
    NSInteger syncEventID = [[NSUserDefaults standardUserDefaults] integerForKey:@"SyncEventID"];
    if(syncEventID == 0) {
        syncEventID = kFSEventStreamEventIdSinceNow;
    }
    return syncEventID;
}

@end

void fsevents_callback(ConstFSEventStreamRef streamRef,
                       void *userData,
                       size_t numEvents,
                       void *eventPaths,
                       const FSEventStreamEventFlags eventFlags[],
                       const FSEventStreamEventId eventIds[]) {
    FileWatcherManager *self = (__bridge FileWatcherManager *)userData;
    NSArray *pathArr = (__bridge NSArray*)eventPaths;
    FSEventStreamEventId lastRenameEventID = 0;
    NSString *lastPath = nil;
    for(int i = 0; i < numEvents; i++){
        if (i > 0) {
            break;
        }
        FSEventStreamEventFlags flag = eventFlags[i];
//        if(kFSEventStreamEventFlagItemCreated & flag) {
//            NSLog(@"create file: %@", pathArr[i]);
//        }
        if(kFSEventStreamEventFlagItemRenamed & flag) {
            FSEventStreamEventId currentEventID = eventIds[i];
            NSString *currentPath = pathArr[i];
            if (currentEventID == lastRenameEventID + 1) {
                // 重命名或者是移动文件
//                NSLog(@"mv %@ %@", lastPath, currentPath);
            } else {
                // 其他情况, 例如移动进来一个文件, 移动出去一个文件, 移动文件到回收站
                if ([[NSFileManager defaultManager] fileExistsAtPath:currentPath]) {
                    // 移动进来一个文件
//                    NSLog(@"move in file: %@", currentPath);
                    [self modifyFileName:pathArr[i]];
                } else {
                    // 移出一个文件
//                    NSLog(@"move out file: %@", currentPath);
                }
            }
            lastRenameEventID = currentEventID;
            lastPath = currentPath;
        }
//        if(kFSEventStreamEventFlagItemRemoved & flag) {
//            NSLog(@"remove: %@", pathArr[i]);
//        }
        if(kFSEventStreamEventFlagItemModified & flag) {
            [self modifyFileName:pathArr[i]];
//            NSLog(@"modify: %@", pathArr[i]);
        }
    }
    [self updateEventID];
}
