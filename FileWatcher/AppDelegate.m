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
#import "KZServerManager.h"

#define PYSeverPort 8000

@interface AppDelegate ()

@property (nonatomic, strong) FileWatcherSocketManager *socketManager;
@property (nonatomic, strong) FileWatcherManager *watcherManager;

@property (nonatomic, strong) NSStatusItem *statusItem;
@property (nonatomic, strong) NSMenuItem *connectItem;
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
        self.connectItem.submenu = connectorMenu;
        [self updateStatusBarWithIsConnected:connectors.count > 0];
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
//    [PYSeverUtil closeSever:PYSeverPort];
//    [PYSeverUtil startSever:PYSeverPort path:path];
    
    if ([KZServerManager shareServerManager].isRunning) {
        [[KZServerManager shareServerManager] stopServer];
        [self addMenu:NO];
    } else {
        [[KZServerManager shareServerManager] customPort:PYSeverPort];
        NSError *error = [[KZServerManager shareServerManager] startServer];
        [self addMenu:error == nil];
    }
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

- (void)addMenu:(BOOL)serverOK {
    //初始化statusItem
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    //修改状态栏图标
    [self updateStatusBarWithIsConnected:NO];
    
    NSMenu *menu = [[NSMenu alloc] init];
    
    //监控状态
    NSMenuItem *watcherItem = [NSMenuItem new];
    watcherItem.title = _S(@"正在监控%@", [self.modulePath lastPathComponent]);
    [menu addItem:watcherItem];
    
    //服务状态
    if (serverOK) {
        NSMenuItem *serverItem = [[NSMenuItem alloc] initWithTitle:@"服务开启中" action:@selector(serverAction) keyEquivalent:@""];
        [menu addItem:serverItem];
    } else {
        NSMenuItem *failedItem = [NSMenuItem new];
        failedItem.title = @"服务开启失败";
        [menu addItem:failedItem];
    }
    
    //链接状态
    NSMenuItem *connectItem = [NSMenuItem new];
    connectItem.title = @"已连接";
    connectItem.submenu = [NSMenu new];
    [menu addItem:connectItem];
    self.connectItem = connectItem;
    
    //退出
    NSMenuItem *quitItem = [[NSMenuItem alloc] initWithTitle:@"退出" action:@selector(quitAction) keyEquivalent:@""];
    [menu addItem:quitItem];
    
    self.statusItem.menu = menu;
}

- (void)updateStatusBarWithIsConnected:(BOOL)connected {
    NSStatusBarButton *button = self.statusItem.button;
    NSString *imageName = connected ? @"menu_icon_orange" : @"menu_icon_blue";
    NSImage *buttonImage = [NSImage imageNamed:imageName];
    [buttonImage setSize:NSMakeSize(18, 18)];
    button.image = buttonImage;
}

- (void)serverAction {
    NSWorkspace *workspace = [NSWorkspace sharedWorkspace];
    NSURL *url = [NSURL URLWithString:_S(@"http://localhost:%d", PYSeverPort)];
    [workspace openURL:url];
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
