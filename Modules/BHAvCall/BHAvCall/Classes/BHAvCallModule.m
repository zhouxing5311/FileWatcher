//
//  BHAvCallModule.m
//  BHAvCall
//
//  Created by xucg on 2021/3/3.
//

#import "BHModuler.h"
#import "KZRouter.h"

@interface BHAvCallModule : NSObject <BHModuleProtocol>

@end

@implementation BHAvCallModule

+ (void)load {
    [BHModuler registerModule:self.class];
}

+ (void)appDidFinishLaunching {
    [[KZRouter shareRouter] initRouter:kRouterHost withInfoPlists:@[@"BHAvCall.plist"]];
}

+ (void)appDidBecomeActive {
    
}

+ (void)appDidEnterBackground {
    if (BHRouter.avCallModule.netMeetingWindowIsFullScreenShowing && BHRouter.avCallModule.netMeetingWindowIsLandscapeShowing) {
        // 在进后台前需要把屏幕转成竖屏,否则再进前台时其余模块有的界面会出现错乱
        [BHRouter.avCallModule netMeetingWindowRotate];
    }
}

+ (void)appWillEnterForeground {
    
}

+ (void)appWillResignActive {
    
}

+ (void)appWillTerminate {
    
}

@end
