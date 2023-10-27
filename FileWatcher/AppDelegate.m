//
//  AppDelegate.m
//  FileWatcher
//
//  Created by 周兴 on 2022/7/20.
//

#import "AppDelegate.h"
#import "FileWatcherManager.h"
#import "FileWatcherSocketManager.h"
#import "FileWatcherUtil.h"
#import "PYSeverUtil.h"

#define PYSeverPort 8000

@interface AppDelegate ()

@property (nonatomic, strong) FileWatcherSocketManager *socketManager;
@property (nonatomic, strong) FileWatcherManager *watcherManager;

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenuItem *item2;
@property (nonatomic, copy) NSString *modulePath;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    //设置监控路径
    NSString *currentAppPath = [[NSBundle mainBundle] bundlePath];
    self.modulePath = [currentAppPath stringByReplacingOccurrencesOfString:@"/FileWatcher.app" withString:@""];
//    //test
//    NSString *modulePath = @"/Users/zhouxing/Desktop/code/boss";
    if ([[NSFileManager defaultManager] fileExistsAtPath:self.modulePath]) {
        //开启python服务
        [self startServer:self.modulePath];
        //添加菜单
        [self addMenu];
    } else {
        //不在目录内
        [self showConfirmAlert:@"目录不合法" confirmTitle:@"关闭" msg:@"" complete:^(BOOL isConfirm) {
            [[NSApplication sharedApplication] terminate:self];
        }];
        return;
    }
    
    //开启server
    self.socketManager = [[FileWatcherSocketManager alloc] init];
    FWWeak(self)
    self.socketManager.connectorChangedBlock = ^(NSArray<NSString *> * _Nonnull connectors) {
        FWStrong(self)
        NSMenu *connectorMenu = [NSMenu new];
        [connectors enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMenuItem *item = [NSMenuItem new];
            item.title = obj;
            [connectorMenu addItem:item];
        }];
        self.item2.submenu = connectorMenu;
    };
    [self.socketManager startTcpServer];
    
    //开始监控文件
    self.watcherManager = [[FileWatcherManager alloc] init];
    [self.watcherManager startWatchWithFilePaths:@[self.modulePath] modifyBlock:^(NSString * _Nonnull fileName) {
        FWStrong(self)
        NSLog(@"改变了文件：%@", fileName);
        //进行文件类型过滤
        [self.socketManager sendStringToClient:fileName];
//        [self showAlertWithTitle:[NSString stringWithFormat:@"文件改变：%@", fileName]];
    }];
}

- (void)startServer:(NSString *)path {
    [PYSeverUtil closeSever:PYSeverPort];
    [PYSeverUtil startSever:PYSeverPort path:path];
    
    NSLog(@"开启py完毕");
}

//展示弹窗
- (void)showAlertWithTitle:(NSString *)title {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"OK"];
    [alert setMessageText:title];
//    [alert setInformativeText:msg.length ? msg : @""];
    [alert setAlertStyle:NSAlertStyleInformational];
    [alert runModal];
}

//展示确认弹窗
- (void)showConfirmAlert:(NSString *_Nullable)title
            confirmTitle:(NSString *)confirmTitle
                     msg:(NSString *_Nullable)msg
                complete:(void(^)(BOOL isConfirm))complete {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:confirmTitle];
//    [alert addButtonWithTitle:@"取消"];
    [alert setMessageText:title];
    [alert setInformativeText:msg.length ? msg : @""];
    [alert setAlertStyle:NSAlertStyleInformational];
    NSModalResponse response = [alert runModal];
    if (response == 1000) {
        !complete ?: complete(YES);
    }
}

- (void)addMenu {
    //初始化statusItem
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    NSStatusBarButton *button = self.statusItem.button;
    NSImage *buttonImage = [NSImage imageNamed:@"menu_icon"];
    [buttonImage setSize:NSMakeSize(18, 18)];
    button.image = buttonImage;
    
    NSMenu *menu = [[NSMenu alloc] init];
    
    NSMenuItem *item1 = [NSMenuItem new];
    item1.title = _S(@"正在监控%@", [self.modulePath lastPathComponent]);
    [menu addItem:item1];
    
    NSMenuItem *item2 = [NSMenuItem new];
    item2.title = @"已连接";
    item2.submenu = [NSMenu new];
    [menu addItem:item2];
    self.item2 = item2;
    
    NSMenuItem *item3 = [[NSMenuItem alloc] initWithTitle:@"退出" action:@selector(quitAction) keyEquivalent:@""];
    [menu addItem:item3];
    
    self.statusItem.menu = menu;
}

- (void)quitAction {
    [[NSApplication sharedApplication] terminate:self];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [PYSeverUtil closeSever:PYSeverPort];
    
    NSLog(@"程序退出了");
}


- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
