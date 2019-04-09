//
//  AppDelegate.m
//  EVLaunchProtectionDemo
//
//  Created by Ever on 2019/4/9.
//  Copyright © 2019 Ever. All rights reserved.
//

#import "AppDelegate.h"
#import "EVLaunchProtection.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.

    //------------------保护流程------------------
    [[EVLaunchProtection shared] configureStrategyWithShallowRepair:^{
        [self clearAppVersion];
    } deepRepair:^{
        [self clearCacheVersion];
    } hotfix:^(EVLaunchProtectionHotfixFinishedBlock  _Nonnull hotfixFinishedBlock) {
        //这里模拟请求热修复包
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_global_queue(0, 0), ^{
            //请求完毕, 应用热修复包。。。
            [self clearUUID];
            
            //热修复包处理完毕了，通知 EVLaunchProtection，可以解除对主线程的阻塞了。
            hotfixFinishedBlock();
        });
    } log:^(EVLaunchProtectionState state) {
        NSLog(@"EVLaunchProtectionState:%lu",(unsigned long)state);
    }];
    
    [[EVLaunchProtection shared] start];
    
    
    //--------------------业务流程-------------------------
    
    NSString *appVersion = [self readLocalAppVersion];
    if ([appVersion isEqualToString:@"0.0.1"]) {
        NSLog(@"使用的旧版本app，需要升级到最新。。。");
    }
    
    NSString *cacheVersion = [self readLocalCacheVersion];
    if ([cacheVersion isEqualToString:@"0.0.1"]) {
        NSLog(@"使用的旧缓存，需要迁移数据。。。");
    }
    
    NSString *uuid = [self readLocalUUID];
    if (uuid.length > 0) {
        NSLog(@"试用期结束，请登录app吧。。。");
    }
    
    return YES;
}

- (NSString *)readLocalAppVersion {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"appVersion"];
}

- (void)clearAppVersion {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"appVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)readLocalCacheVersion {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"cacheVersion"];
}

- (void)clearCacheVersion {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"cacheVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSString *)readLocalUUID {
    return [[NSUserDefaults standardUserDefaults] objectForKey:@"uuid"];
}

- (void)clearUUID {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"uuid"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
