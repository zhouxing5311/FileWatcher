//
//  FileWatcherUtil.m
//  FileWatcher
//
//  Created by 周兴 on 2022/7/22.
//

#import "FileWatcherUtil.h"
#import "STPrivilegedTask.h"

@implementation FileWatcherUtil

+ (SEResult *)runWithCmd:(NSString *)format,... {
    SEResult *result = [SEResult new];
    NSString *cmd = nil;
    @try {
        va_list args;
        if (format) {
            va_start(args, format);
            cmd = [[NSString alloc] initWithFormat:format arguments:args];
            va_end(args);
        }
        STPrivilegedTask *privilegedTask = [[STPrivilegedTask alloc] init];
        NSMutableArray *components = [[cmd componentsSeparatedByString:@" "] mutableCopy];
        
        NSString *launchPath = components[0];
        [components removeObjectAtIndex:0];
        
        [privilegedTask setLaunchPath:launchPath];
        [privilegedTask setArguments:components];
        [privilegedTask setCurrentDirectoryPath:[[NSBundle mainBundle] resourcePath]];
        
        //set it off
        OSStatus err = [privilegedTask launch];
        result.err = err;
        [privilegedTask waitUntilExit];
        
        // Success!  Now, start monitoring output file handle for data
        NSFileHandle *readHandle = [privilegedTask outputFileHandle];
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        result.outputStr = outputString;
        
        return result;
    } @catch(NSException *e) {
        return nil;
    }
}

@end
