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
#import "KZServerManager.h"
#import "FWAlertUtils.h"

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
    //当前路径
    NSString *currentAppPath = [[NSBundle mainBundle] bundlePath];
    self.modulePath = [currentAppPath stringByDeletingLastPathComponent];
    
    //开启文件服务
    [self setupFileServer];
    
    //设置长连接
    [self setupSocketManager];
    
    //开始监控文件
    [self setupFileWatcher];
}

#pragma mark - Setup
//开启文件服务
- (void)setupFileServer {
    if ([KZServerManager shareServerManager].isRunning) {
        [[KZServerManager shareServerManager] stopServer];
        [self addMenu:NO];
    } else {
        [[KZServerManager shareServerManager] customPort:PYSeverPort];
        NSError *error = [[KZServerManager shareServerManager] startServer];
        [self addMenu:error == nil];
    }
}

//设置长连接
- (void)setupSocketManager {
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
}

//开始监控文件
- (void)setupFileWatcher {
    self.watcherManager = [[FileWatcherManager alloc] init];
    FWWeak(self)
    [self.watcherManager startWatchWithFilePaths:@[self.modulePath] modifyBlock:^(NSString * _Nonnull fileName) {
        FWStrong(self)
        NSLog(@"改变了文件：%@", fileName);
        //进行文件类型过滤
        [self.socketManager sendStringToClient:fileName];
    }];
}

#pragma mark - Methods
//添加菜单
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


#pragma mark - NSApplicationDelegate
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSLog(@"程序退出了");
}

- (BOOL)applicationSupportsSecureRestorableState:(NSApplication *)app {
    return YES;
}


@end
