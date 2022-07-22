//
//  SEResult.h
//  SwitchEnv!
//
//  Created by 李遵源 on 2018/4/22.
//  Copyright © 2018年 李遵源. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SEResult : NSObject

@property (nonatomic, assign) OSStatus err;
@property (nonatomic, strong) NSString *outputStr;

@end
