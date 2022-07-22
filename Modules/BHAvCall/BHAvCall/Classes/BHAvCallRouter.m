//
//  BHAvCallRouter.m
//  BHAvCall
//
//  Created by xucg on 2021/6/8.
//

#import "BHRouter.h"
#import "BHMusicPlayerVC.h"
#import "BHNetMeetingCreateVC.h"
#import "BHNetMeetingWaitingVC.h"
#import "BHNetMeetingWindow.h"
#import "BHNetMeetingVM.h"
#import "BHNetMeetingVC.h"
#import "KZPrivacyHelper.h"



@interface BHAvCallRouter : NSObject <BHAvCallRouterProtocol>

@end

@implementation BHAvCallRouter

+ (void)load {
    [BHRouter registerModule:self.class];
}

#pragma mark - BHAvCallRouterProtocol

+ (void)makeAvCallToId:(SInt64)toId isAudio:(BOOL)isAudio {
    
    [BHHttp get:@"api/link/meeting/white/user/check" params:@{@"userId":@(toId)} resultBlock:^(id  _Nonnull response, NSError * _Nonnull error) {
        BOOL whiteUser = getBOOLFromDict(response, @"whiteUser");
        if (whiteUser) {
            [BHNetMeetingWaitingVC makeCallWithId:toId isAudio:isAudio];
        }else{
            [BHHud showFailedMsg:@"邀请失败，对方暂不支持该功能"];
        }
    }];

}

+ (void)receiveAvCallWithRoomId:(NSString*)roomId conferenceId:(NSString *)conferenceId fromId:(SInt64)fromId toId:(SInt64)toId isAudio:(BOOL)isAudio {

    [BHNetMeetingWaitingVC calledWithRoomId:roomId conferenceId:conferenceId fromId:fromId toId:toId isAudio:isAudio];
    
}

+ (void)openMusicPlayerWith:(BHFilePreviewModel*)file {
    BHMusicPlayerVC *tmpVC = [[BHMusicPlayerVC alloc] init];
    tmpVC.file = file;
    [BHNavi pushVC:tmpVC];
}

+ (void)openMeetingCreateVC:(BHGroupObj *)group source:(NSInteger)source{
    if (![BHNetMeetingWindow newMeetingAvailable]) {
        return;
    }
    BHNetMeetingCreateVC *target = [[BHNetMeetingCreateVC alloc] init];
    target.group = group;
    target.source = source;
    [BHNavi pushVCFromBottom:target];
}

// 加入会议需更长的加载时间
+ (void)openMeetingVCWithRoomId:(NSString *)roomId {
    BHNetMeetingWindow *window = [BHNetMeetingWindow netMeetingWindow];
    BHNetMeetingVM *vm = window.vm;
    if ([vm.roomId isEqualToString:roomId] && BHNetMeetingWindow.isShowing) {
        [window resetAction];
        return;
    }
    [KZPrivacyHelper checkPrivacy:KZPrivacyCheckTypeMicrophone configer:^(KZPrivacyConfiger *configer) {
        configer.showAlertWhenDenied = NO;
    } resultBlock:^(KZPrivacyResulter *resulter) {
        BOOL audioVailable = resulter.microphoneStatus == KZPrivacyStatusAuthorized;
        [BHHud showLoading];
        [BHNetMeetingVM joinNetMeeting:roomId configVMBlock:^(BHNetMeetingVM * _Nonnull vm) {
            vm.isMute = !audioVailable;
        } complite:^(BHNetMeetingVM * _Nonnull vm) {
            if (vm) {
                [BHHud dismiss];
                vm.source = BHNetMeetingSourceTypeJoin;
                [BHNetMeetingVC show:vm];
            }
        }];
    }];
    
}

+ (BOOL)netMeetingWindowIsFullScreenShowing {
    return [BHNetMeetingWindow isFullScreenShowing];
}

+ (BOOL)netMeetingWindowIsLandscapeShowing {
    return [BHNetMeetingWindow netMeetingWindow].vm.isLandscape;
}

+ (void)netMeetingWindowRotate {
    [[BHNetMeetingWindow netMeetingWindow] rotateAction:NO];
}

+ (BOOL)netMeetingWindowIsShowing {
    return [BHNetMeetingWindow isShowing];
}

+ (NSInteger)netMeetintType {
    return [BHNetMeetingWindow meetingType];
}

+ (BOOL)isNetMeetingWindow:(UIWindow *)window {
    return [window isKindOfClass:BHNetMeetingWindow.class];
}

+ (void)netMeetingWindowFloatAction {
    return [BHNetMeetingWindow floatAction];
}

+ (UIViewController *)getNetMeetingNavigationController {
    return [BHNetMeetingWindow getNetMeetingNavigationController];
}

+ (void)router_openMeeting:(NSDictionary*)dict {
    NSString *roomId = dict[@"roomId"];
    [self openMeetingVCWithRoomId:roomId];
}

@end
