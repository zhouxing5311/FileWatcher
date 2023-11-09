//
//  KZHTTPConnection.m
//  PerformanceMonitoring
//
//  Created by Yaping Liu on 2018/5/18.
//  Copyright © 2018年 Yaping Liu. All rights reserved.
//

#import "KZHTTPConnection.h"
#import "HTTPFileResponse.h"
#import "HTTPMessage.h"
#import "KZHTTPDataResponse.h"

#define kFormat(path)   [NSString stringWithFormat:@"/%@",path]
#define kPlaceHolder    @"$##$"
#define kXmlResource    @"/xmlResource"

@implementation KZHTTPConnection

- (NSData *)preprocessResponse:(HTTPMessage *)response {
    [response setHeaderField:@"Access-Control-Allow-Origin" value:@"*"];
    [response setHeaderField:@"Access-Control-Allow-Headers" value:@"X-Requested-With"];
    [response setHeaderField:@"Access-Control-Allow-Methods" value:@"PUT,POST,GET,DELETE,OPTIONS"];
    return [super preprocessResponse:response];
}

- (NSData *)preprocessErrorResponse:(HTTPMessage *)response {
    [response setHeaderField:@"Access-Control-Allow-Origin" value:@"*"];
    [response setHeaderField:@"Access-Control-Allow-Headers" value:@"X-Requested-With"];
    [response setHeaderField:@"Access-Control-Allow-Methods" value:@"PUT,POST,GET,DELETE,OPTIONS"];
    return [super preprocessErrorResponse:response];
}

#pragma mark -- HTTPConnection
- (BOOL)supportsMethod:(NSString *)method atPath:(NSString *)path
{
    
    return [super supportsMethod:method atPath:path];
}

- (BOOL)expectsRequestBodyFromMethod:(NSString *)method atPath:(NSString *)path
{
    
    return NO;
}

- (NSObject<HTTPResponse> *)httpResponseForMethod:(NSString *)method URI:(NSString *)path
{
    if ([path isEqualToString:@"/xmlResource"]) {
        //获取xml资源
        NSArray<NSString *> *xmlPaths = [[NSUserDefaults standardUserDefaults] objectForKey:kXmlResourceKey];
        NSMutableString *xmlResourceString = @"".mutableCopy;
        for (NSString *path in xmlPaths) {
            [xmlResourceString appendFormat:@"%@%@", xmlResourceString.length == 0 ? @"" : @"\n", path];
        }
        NSData *xmlResourceData = [xmlResourceString dataUsingEncoding:NSUTF8StringEncoding];
        KZHTTPDataResponse *response = [[KZHTTPDataResponse alloc] initWithGeneralData:xmlResourceData];
        return response;
    } else {
        //本地文件
        return [self localResponseWithPath:path method:method];
    }
}

//local
- (NSObject<HTTPResponse> *)localResponseWithPath:(NSString *)path method:(NSString *)method {
    NSString *homeDicPath = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
    homeDicPath = [homeDicPath stringByAppendingPathComponent:path];
    
    BOOL isDic = NO;
    [[NSFileManager defaultManager] fileExistsAtPath:homeDicPath isDirectory:&isDic];
    if (isDic) {
        //assemble contents
        NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:[NSURL URLWithString:homeDicPath] includingPropertiesForKeys:@[] options:NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles error:nil];
        NSMutableString *content = [[NSMutableString alloc] initWithString:@""];

        for (NSInteger i = paths.count - 1; i >= 0; i--) {
            NSURL *url = paths[i];
            NSString *lastComponet = kFormat(url.lastPathComponent);
            NSString *nextFilePath = [path stringByAppendingPathComponent:lastComponet];
            NSString *c = [NSString stringWithFormat:@"<li><a href = %@>%@</a><br /><br />",nextFilePath,lastComponet];
            [content appendString:c];
        }

        //generate HTML
        NSString *homeFilePath = [[NSBundle mainBundle] pathForResource:@"fw_home" ofType:@"html"];
        NSString *HTMLString = [NSString stringWithContentsOfFile:homeFilePath encoding:NSUTF8StringEncoding error:nil];
        HTMLString = [HTMLString stringByReplacingOccurrencesOfString:kPlaceHolder withString:content];

        return [[KZHTTPDataResponse alloc] initWithHTMLData:[HTMLString dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        return [[HTTPFileResponse alloc] initWithFilePath:homeDicPath forConnection:self];
        
//        NSData *data = [NSData dataWithContentsOfFile:homeDicPath options:NSDataReadingMappedIfSafe error:nil];
//        return [[HTTPDataResponse alloc] initWithData:data];
//        return [[KZHTTPDataResponse alloc] initWithGeneralData:data];
    }
}

@end
