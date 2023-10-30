//
//  KZHTTPDataResponse.m
//  PerformanceMonitoring
//
//  Created by Yaping Liu on 2018/6/5.
//  Copyright © 2018年 Yaping Liu. All rights reserved.
//

#import "KZHTTPDataResponse.h"

@interface KZHTTPDataResponse ()

{
    NSUInteger offset;
    NSData *data;
    NSString *contentType;
}

@end

@implementation KZHTTPDataResponse

- (id)initWithHTMLData:(NSData *)htmlData {
    if((self = [super init]))
    {
        
        offset = 0;
        data = htmlData;
        contentType = @"text/html";
    }
    return self;

}

- (id)initWithGeneralData:(NSData *)generalData {
    if((self = [super init]))
    {
        
        offset = 0;
        data = generalData;
        contentType = @"application/octet-stream";
        
    }
    return self;

}

- (UInt64)contentLength
{
    UInt64 result = (UInt64)[data length];
    
    return result;
}

- (UInt64)offset
{
    
    return offset;
}

- (void)setOffset:(UInt64)offsetParam
{
    offset = (NSUInteger)offsetParam;
}

- (NSData *)readDataOfLength:(NSUInteger)lengthParameter
{
    NSUInteger remaining = [data length] - offset;
    NSUInteger length = lengthParameter < remaining ? lengthParameter : remaining;
    
    void *bytes = (void *)([data bytes] + offset);
    
    offset += length;
    
    return [NSData dataWithBytesNoCopy:bytes length:length freeWhenDone:NO];
}

- (BOOL)isDone
{
    BOOL result = (offset == [data length]);
    
    return result;
}

- (NSDictionary *)httpHeaders {
    return @{@"Content-Type":contentType ?:@"application/octet-stream"};
}

@end
