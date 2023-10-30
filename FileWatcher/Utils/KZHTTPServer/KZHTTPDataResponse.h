//
//  KZHTTPDataResponse.h
//  PerformanceMonitoring
//
//  Created by Yaping Liu on 2018/6/5.
//  Copyright © 2018年 Yaping Liu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTTPResponse.h"

@interface KZHTTPDataResponse : NSObject <HTTPResponse>

- (id)initWithHTMLData:(NSData *)htmlData;

- (id)initWithGeneralData:(NSData *)generalData;

@end
