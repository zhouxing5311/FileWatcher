//
//  BHContactRouter.m
//  BHContacts
//
//  Created by xucg on 2021/6/8.
//

#import "BHContactSelectorVC.h"
#import "BHDB.h"
#import "BHUserProfileVC.h"
#import "BHUserImpressionSelectSheet.h"
#import "BHXLogVC.h"
#import "BHFriendApplyListVC.h"
#import "BHSelectorManager.h"
#import "BHOrganizationVC.h"
#import "BHGroupMemberSelectVC.h"
#import "BHUrgentSelectorVC.h"
#import "BHChatSelectorVC.h"
#import "BHContactsSelectingVC.h"
#import "BHFriendApplyVC.h"
#import "BHGroupProfileVC.h"
#import "BHChatShareSelectorVC.h"
#import "BHNavigationController.h"
#import "BHSessionSelectorVC.h"

@interface BHContactRouter : NSObject <BHContactRouterProtocol>

@end

@implementation BHContactRouter

+ (void)load {
    [BHRouter registerModule:self.class];
}

+ (void)openUserProfileWithUid:(SInt64)uid {
    if (uid <= 0) {return;}
    [self openUserProfileWithUid:uid enterType:0];
}

//带enterType记录
+ (void)openUserProfileWithUid:(SInt64)uid enterType:(NSInteger)enterType {
    if ([self isSystemId:uid]) {
        // todo:xucg 会有死循环
        [BHRouter.chatModule openChatWithId:uid isGroup:NO];
        return;
    }

    BHUserProfileVC *profileVC = [[BHUserProfileVC alloc] init];
    profileVC.userId = uid;
    profileVC.enterType = enterType;
    [BHNavi pushVC:profileVC];
}

+ (void)openUserApplyWithUid:(SInt64)uid {
    if ([self isSystemId:uid]) {
        return;
    }
    BHFriendApplyVC *applyVC = [[BHFriendApplyVC alloc] init];
    applyVC.userId = uid;
    [BHNavi pushVC:applyVC];
}

+ (void)openGroupProfileWithShareCard:(BHMsgModel *)msgInfo {
    
    BHGroupProfileVC *profileVC = [[BHGroupProfileVC alloc] init];
    profileVC.msgInfo = msgInfo;
    [BHNavi pushVC:profileVC];
    
    
}


+ (void)openOrganizationWithDeptId:(SInt64)deptId {
    NSArray *list = [BHDB.deptTable queryDepartPathById:deptId];
    if (list.count > 0) {
        BHOrganizationVC *target = [[BHOrganizationVC alloc] init];
        [target setupDepartList:list];
        [BHNavi pushVC:target];
    } else {
        [BHHud showFailedMsg:@"你没有查看该部门权限"];
    }
}

+ (void)selectContactWithManagerBlock:(void(^)(BHSelectorManager *manager))managerBlock
                                selectedBlock:(void(^)(NSArray *itemArray))selectedBlock
                          teamBeSelectedBlock:(void (^ _Nullable)(BHContactObj *team))teamBeSelectedBlock {
    
    BHSelectorManager * manager = [[BHSelectorManager alloc]init];
    managerBlock(manager);
    manager.selectType = BHSelectTypeContactsOrGroup; // 默认只能选人或群
    
    BHContactSelectorVC *selectorVC = [[BHContactSelectorVC alloc] init];
    selectorVC.model = manager;
    if (manager.title.length > 0) {
        selectorVC.title = manager.title;
    }
    selectorVC.finishBlock = selectedBlock;
    selectorVC.teamBeSelectedBlock = teamBeSelectedBlock;
    [BHNavi pushVCFromBottom:selectorVC];
}

// 同时多选人和群
+ (void)selectContactWithManager:(void (^)(BHSelectorManager * _Nonnull))managerBlock completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, NSArray * _Nonnull))completionBlock {
    BHSelectorManager * manager = [[BHSelectorManager alloc]init];
    managerBlock(manager);
    
    BHContactSelectorVC *selectorVC = [[BHContactSelectorVC alloc] init];
    selectorVC.model = manager;
    if (manager.title.length > 0) {
        selectorVC.title = manager.title;
    }
    selectorVC.completionBlock = completionBlock;
    [BHNavi pushVCFromBottom:selectorVC];
    
}

+ (void)showSelectingContactWithManager:(void (^)(BHSelectorManager * _Nonnull))managerBlock completion:(void (^)(NSArray * _Nonnull, NSArray * _Nonnull, NSArray * _Nonnull))completionBlock {
    BHSelectorManager * manager = [[BHSelectorManager alloc]init];
    managerBlock(manager);
    
    BHContactsSelectingVC *selecting = [[BHContactsSelectingVC alloc] init];
    selecting.model = manager;
    selecting.completionBlock = completionBlock;
    [BHNavi pushVCFromBottom:selecting];
}

+ (void)selectChatWithManagerBlock:(void(^)(BHSelectorManager *manager))managerBlock
                     selectedBlock:(void (^)(NSArray *itemArray))selectedBlock {
    BHSelectorManager * manager = [[BHSelectorManager alloc]init];
    manager.onlySelectFriendShip = YES;
    managerBlock(manager);
    
    BHSessionSelectorVC *chatSelector = [[BHSessionSelectorVC alloc] init];
    chatSelector.selectManager = manager;
    chatSelector.finishBlock = selectedBlock;
    [BHNavi pushVCFromBottom:chatSelector];
}

+ (void)openForwardListWithTip:(NSString*)tip selectedBlock:(void (^)(NSArray *itemArray, NSString *textMsg))selectedBlock {
    [self openForwardListWithTip:tip animation:YES selectedBlock:selectedBlock];
}

+ (void)openForwardListWithTip:(NSString*)tip hideTextField:(BOOL)hideTextField selectedBlock:(void (^)(NSArray *itemArray, NSString *textMsg))selectedBlock {
    [self openForwardListWithTip:tip animation:YES hideTextField:hideTextField selectedBlock:selectedBlock];
}

+ (void)presentOpenForwardListWithTip:(NSString *)tip hideTextField:(BOOL)hideTextField selectedBlock:(void (^)(NSArray * _Nonnull, NSString * _Nonnull))selectedBlock {
    BHChatSelectorVC *chatSelector = [[BHChatSelectorVC alloc] init];
    chatSelector.finishBlock = selectedBlock;
    chatSelector.hideTextField = hideTextField;
    chatSelector.forwardTip = tip;
    chatSelector.showType = 1;
    [BHNavi.getTopPushedVC presentViewController:chatSelector animated:YES completion:nil];
}

+ (void)openForwardListWithTip:(NSString*)tip animation:(BOOL)animation selectedBlock:(void (^)(NSArray *itemArray, NSString *textMsg))selectedBlock {
    [self openForwardListWithTip:tip animation:animation hideTextField:NO selectedBlock:selectedBlock];
}

+ (void)openForwardListWithTip:(NSString*)tip animation:(BOOL)animation hideTextField:(BOOL)hideTextField selectedBlock:(void (^)(NSArray *itemArray, NSString *textMsg))selectedBlock {
    BHChatSelectorVC *chatSelector = [[BHChatSelectorVC alloc] init];
    chatSelector.finishBlock = selectedBlock;
    chatSelector.forwardTip = tip;
    chatSelector.hideTextField = hideTextField;
    if (!animation) {
        chatSelector.isPushFromBottom = YES;
        [BHNavi pushVC:chatSelector animated:NO];
    } else {
        [BHNavi pushVCFromBottom:chatSelector];
    }
}

+ (void)openForwardListWithTitle:(NSString * _Nullable)title selectedBlock:(void (^)(NSArray *itemArray, NSString *textMsg))selectedBlock {
    BHChatSelectorVC *chatSelector = [[BHChatSelectorVC alloc] init];
    chatSelector.title = title;
    chatSelector.finishBlock = selectedBlock;
    [BHNavi pushVCFromBottom:chatSelector];
}
///
+ (void)openShareForwardListWithTip:(NSString *_Nullable)tip selectedBlock:(void (^)(NSArray *itemArray, NSString *textMsg))selectedBlock {
    
    BHChatShareSelectorVC *chatSelector = [[BHChatShareSelectorVC alloc] init];
    chatSelector.finishBlock = selectedBlock;
    chatSelector.forwardTip = tip;
    BHNavigationController *rootVC = [[BHNavigationController alloc] initWithRootViewController:chatSelector];
    [BHNavi presentVC:rootVC];
}

+ (void)showExpressionSheetWithUid:(SInt64)uid fromChat:(BOOL)fromChat completion:(dispatch_block_t)completionBlock {
    BHUserImpressionSelectSheet *sheet = [[BHUserImpressionSelectSheet alloc] init];
    sheet.userId = uid;
    sheet.fromChat = fromChat;
    sheet.completionBlock = completionBlock;
    [sheet show];
}

+ (void)selectMemberInGroup:(id)groupInfo
                      title:(NSString * _Nullable)title
                   maxCount:(int)maxCount
                selectArray:(NSArray * _Nullable)selectArray
                hiddenArray:(NSArray * _Nullable)hiddenArray
           isGroupMsgSearch:(BOOL)isGroupMsgSearch
          showIdentityBadge:(BOOL)showIdentityBadge
        dismissAfterConfirm:(BOOL)dismissAfterConfirm
                finishBlock:(void(^ _Nullable)(NSArray * _Nullable userArray))finishBlock {
    BHGroupMemberSelectVC *selectVC = [[BHGroupMemberSelectVC alloc] init];
    selectVC.title = title ?: @"选择执行人";
    selectVC.groupInfo = groupInfo;
    selectVC.maxSelectCount = maxCount;
    [selectVC updateSelectingList:selectArray];
    [selectVC updateHiddenList:hiddenArray];
    selectVC.isGroupMsgSearch = isGroupMsgSearch;
    selectVC.showIdentityBadge = showIdentityBadge;
    selectVC.dismissAfterConfirm = dismissAfterConfirm;
    selectVC.finishBlock = finishBlock;
    
    [BHNavi pushVCFromBottom:selectVC];
}

+ (void)selectMemberInGroup:(id)groupInfo
                      title:(NSString * _Nullable)title
                   maxCount:(int)maxCount
                selectArray:(NSArray * _Nullable)selectArray
              selectedArray:(NSArray * _Nullable)selectedArray
                hiddenArray:(NSArray * _Nullable)hiddenArray
           isGroupMsgSearch:(BOOL)isGroupMsgSearch
          showIdentityBadge:(BOOL)showIdentityBadge
        dismissAfterConfirm:(BOOL)dismissAfterConfirm
                finishBlock:(void(^ _Nullable)(NSArray * _Nullable userArray))finishBlock {
    
    BHGroupMemberSelectVC *selectVC = [[BHGroupMemberSelectVC alloc] init];
    selectVC.title = title ?: @"选择执行人";
    selectVC.groupInfo = groupInfo;
    selectVC.maxSelectCount = maxCount;
    [selectVC updateSelectingList:selectArray];
    [selectVC updateSelectedList:selectedArray];
    [selectVC updateHiddenList:hiddenArray];
    selectVC.isGroupMsgSearch = isGroupMsgSearch;
    selectVC.showIdentityBadge = showIdentityBadge;
    selectVC.dismissAfterConfirm = dismissAfterConfirm;
    selectVC.finishBlock = finishBlock;
    
    [BHNavi pushVCFromBottom:selectVC];
}

+ (void)openUrgentSelectorWithGroupId:(SInt64)groupId
                        selectedArray:(NSArray * _Nullable)selectedArray
                       selectingArray:(NSArray * _Nullable)selectingArray
                            hideArray:(NSArray * _Nullable)hideArray
                          finishBlock:(void(^ _Nullable)(NSArray * _Nullable userArray, int urgentType))finishBlock {
    int maxSelectCount = BHAppConfigurator.urgentMaxCount ?: 10;
    BHUrgentSelectorVC *selectVC = [[BHUrgentSelectorVC alloc] init];
    selectVC.groupInfo = [BHDB.groupTable queryGroupWithId:groupId];
    selectVC.maxSelectCount = maxSelectCount;
    selectVC.title = @"加急消息";
    [selectVC updateSelectedList:selectedArray];
    [selectVC updateSelectingList:selectingArray];
    [selectVC updateHiddenList:hideArray];
    selectVC.confirmBlock = finishBlock;
    [BHNavi pushVCFromBottom:selectVC];
}

+ (BOOL)isSystemId:(SInt64)uid {
    // 助手id最大值
    BOOL isSysId = uid <= 10000;
    
    if (!isSysId) {
        BHUserObj *contact = [BHDB.userTable queryUserWithId:uid];
        if (contact.userType == BHUserTypeSystem) {
            isSysId = YES;
        }
    }
    
    return isSysId;
}

+ (void)openXlogVC {
    BHXLogVC *targetVC = [[BHXLogVC alloc] init];
    [BHNavi pushVC:targetVC];
}

+ (void)router_openUserProfileVC:(NSDictionary *)paramDict {
    SInt64 userId = [paramDict[@"userId"] longLongValue];
    [self openUserProfileWithUid:userId];
}

+ (void)router_openFriendApplyList {
    BHFriendApplyListVC *applyListVC = [[BHFriendApplyListVC alloc] init];
    [BHNavi pushVC:applyListVC];
}

@end
