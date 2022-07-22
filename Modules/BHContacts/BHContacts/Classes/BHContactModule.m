//
//  BHContactsModule.m
//  BHContacts
//
//  Created by xucg on 2019/2/28.
//

#import <KZRouter.h>
@interface BHContactModule: NSObject <BHModuleProtocol>

@end

@implementation BHContactModule

+ (void)load {
    [BHModuler registerModule:self.class];
}

+ (void)appDidFinishLaunching {
    [[KZRouter shareRouter] initRouter:kRouterHost withInfoPlists:@[ @"BHContactRouter.plist" ]];

}

+ (void)appDidEnterBackground {
    
}

+ (void)appWillEnterForeground {
    
}

+ (void)appWillResignActive {
    
}

+ (void)appDidBecomeActive {
    
}

+ (void)appWillTerminate {
    
}

@end
