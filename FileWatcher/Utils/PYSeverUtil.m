//
//  PYSeverUtil.m
//  FileWatcher
//
//  Created by 周兴 on 2023/10/27.
//

#import "PYSeverUtil.h"

@implementation PYSeverUtil

+ (NSString *_Nullable)startSever:(NSInteger)port path:(NSString *)path {
    NSError *error = nil;
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/bin/python3"];
    [task setArguments:@[@"-m", @"http.server", _S(@"%ld", port)]];
    [task setCurrentDirectoryPath:path];
    [task launchAndReturnError:&error];
    NSLog(@"启动错误：%@", error);
    return error.localizedDescription;
}

+ (NSString *_Nullable)closeSever:(NSInteger)port {
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/lsof"];
    [task setArguments:@[@"-i", _S(@":%ld", port)]];

    // 创建管道来捕获标准输出
    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];

    [task launch];

    // 从管道中读取输出
    NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];

    if (output.length == 0) return @"未检测到服务开启";
    
    // 打印输出结果
    NSArray<NSString *> *singleLineArray = [self removeEmptyElements:[output componentsSeparatedByString:@"\n"]];
    if (singleLineArray.count > 1) {
        NSArray<NSString *> *pidInfoArray = [self removeEmptyElements:[singleLineArray[1] componentsSeparatedByString:@" "]];
        if (pidInfoArray.count > 1) {
            NSString *pid = pidInfoArray[1];
            NSLog(@"lsof -i:8000 进程id: %@", pid);
            
            pid_t processIDToKill = [pid intValue];
            if (kill(processIDToKill, SIGKILL) == 0) {
                NSLog(@"成功终止进程 %d", processIDToKill);
            } else {
                NSString *errorString = [NSString stringWithFormat:@"无法终止进程 %d", processIDToKill];
                NSLog(@"%@", errorString);
                return errorString;
            }
        }
    }
    return nil;
}

+ (NSArray<NSString *> *)removeEmptyElements:(NSArray<NSString *> *)array {
    NSMutableArray *arrayM = @[].mutableCopy;
    [array enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.length) [arrayM addObject:obj];
    }];
    return arrayM.copy;
}

@end
