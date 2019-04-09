//
//  EVLaunchProtection.m
//  EVLaunchProtectionDemo
//
//  Created by Ever on 2019/4/9.
//  Copyright © 2019 Ever. All rights reserved.
//

#import "EVLaunchProtection.h"
#import <UIKit/UIKit.h>

#define CURRENT_CRASH_COUNT_KEY      @"EV_CURRENT_CRASH_COUNT_KEY"

#define SHALLOW_REPAIR_FINISHED_KEY  @"EV_SHALLOW_REPAIR_FINISHED_KEY"
#define DEEP_REPAIR_FINISHED_KEY     @"EV_DEEP_REPAIR_FINISHED_KEY"
#define HOTFIX_FINISHED_KEY          @"EV_HOTFIX_FINISHED_KEY"

@interface EVLaunchProtection ()

/**
 当前app启动时crash次数
 */
@property (nonatomic, assign) NSUInteger currentCrashCountOnLaunch;

/**
 浅度修复策略是否执行完毕
 */
@property (nonatomic, assign, getter = isShallowRepairFinished) BOOL shallowRepairFinished;

/**
 深度修复策略是否执行完毕
 */
@property (nonatomic, assign, getter = isDeepRepairFinished) BOOL deepRepairFinished;

/**
 热修复策略是否执行完毕
 */
@property (nonatomic, assign, getter = isHotfixFinished) BOOL hotfixFinished;

/**
 信号量：当执行热修复策略时，阻塞主线程
 */
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation EVLaunchProtection

+ (instancetype)shared {
    static EVLaunchProtection *_launchProtection;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ 
        _launchProtection = [[super allocWithZone:NULL] init];
        _launchProtection.minAppLiveThreshold = 6;
        _launchProtection.thresholdToShallowRepairWhenContinuousCrashOnLaunch = 2;
        _launchProtection.thresholdToDeepRepairWhenContinuousCrashOnLaunch = 3;
        _launchProtection.currentCrashCountOnLaunch = [[_launchProtection localValueForKey:CURRENT_CRASH_COUNT_KEY] integerValue];
        _launchProtection.shallowRepairFinished = [[_launchProtection localValueForKey:SHALLOW_REPAIR_FINISHED_KEY] boolValue];
        _launchProtection.deepRepairFinished = [[_launchProtection localValueForKey:DEEP_REPAIR_FINISHED_KEY] boolValue];
        _launchProtection.hotfixFinished = [[_launchProtection localValueForKey:HOTFIX_FINISHED_KEY] boolValue];
        
        [_launchProtection addObserver];
    });
    return _launchProtection;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [EVLaunchProtection shared];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    return [EVLaunchProtection shared];
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    return [EVLaunchProtection shared];
}

- (void)addObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stop) name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(start) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)removeObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)stop {
    if (self.currentCrashCountOnLaunch > 0) {
        self.currentCrashCountOnLaunch -= 1;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(resetToNormal) object:nil];
}

#pragma mark - PUBLIC API

- (void)configureStrategyWithShallowRepair:(EVLaunchProtectionRepairBlock)shallowRepairBlock
                                deepRepair:(EVLaunchProtectionRepairBlock)deepRepairBlock
                                    hotfix:(EVLaunchProtectionHotfixBlock)hotfixBlock
                                       log:(EVLaunchProtectionLogBlock)logBlock {
    self.shallowRepairBlock = shallowRepairBlock;
    self.deepRepairBlock = deepRepairBlock;
    self.hotfixBlock = hotfixBlock;
    self.logBlock = logBlock;
}

- (void)start {
    //深度修复完成后，如果启动正常，deepRepairFinished 会重置为 NO；如果还是为 YES，则说明 深度修复策略 失败。
    BOOL isDeepRepairInvalid = self.deepRepairFinished;
    
    if (self.currentCrashCountOnLaunch >= self.thresholdToShallowRepairWhenContinuousCrashOnLaunch) {
        if (self.shallowRepairBlock) {
            self.shallowRepairBlock();
            if (!self.shallowRepairFinished) {
                [self logWithState:EVLaunchProtectionStateShallowRepairFinished];
            }
            self.shallowRepairFinished = YES;
        }
    }
    if (self.currentCrashCountOnLaunch >= self.thresholdToDeepRepairWhenContinuousCrashOnLaunch) {
        if (self.deepRepairBlock) {
            self.deepRepairBlock();
            if (!self.deepRepairFinished) {
                [self logWithState:EVLaunchProtectionStateDeepRepairFinished];
            }
            self.deepRepairFinished = YES;
        }
    }
    
    //假设启动时，发生了崩溃；计数 +1.
    self.currentCrashCountOnLaunch += 1;

    if (isDeepRepairInvalid) {
        if (self.hotfixBlock) {
            self.semaphore = dispatch_semaphore_create(0);
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                [self logWithState:EVLaunchProtectionStateHotfixBefore];
                __weak typeof(self) weakSelf = self;
                self.hotfixBlock(^{
                    dispatch_semaphore_signal(weakSelf.semaphore);
                    weakSelf.hotfixFinished = YES;
                    [weakSelf logWithState:EVLaunchProtectionStateHotfixFinished];
                });
            });
            
//            dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)));
            dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
        }
    }
    
    //App 生存时间超过了 minAppLiveThreshold，则认为启动正常，没有崩溃产生，将相关变量，重置到正常状态。
    [self performSelector:@selector(resetToNormal) withObject:nil afterDelay:self.minAppLiveThreshold];
}

- (void)resetToNormal {
    //先输出日志
    if (self.currentCrashCountOnLaunch == 0) {
        [self logWithState:EVLaunchProtectionStateNormal];
    } else if (self.hotfixFinished) {
        [self logWithState:EVLaunchProtectionStateHotfixSuccess];
    } else if (self.deepRepairFinished) {
        [self logWithState:EVLaunchProtectionStateDeepRepairSuccess];
    } else if (self.shallowRepairFinished) {
        [self logWithState:EVLaunchProtectionStateShallowRepairSuccess];
    }
    
    //启动流程正常，恢复正常状态
    self.currentCrashCountOnLaunch = 0;
    self.shallowRepairFinished = NO;
    self.deepRepairFinished = NO;
    self.hotfixFinished = NO;
    
    [self removeObserver];
}

#pragma mark - HELPER ACTION

- (void)saveToLocalWithValue:(id)value forKey:(NSString *)key {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:value forKey:key];
    [userDefaults synchronize];
}

- (id)localValueForKey:(NSString *)key {
    return [[NSUserDefaults standardUserDefaults] objectForKey:key];
}

- (void)logWithState:(EVLaunchProtectionState)state {
    if (self.logBlock) {
        self.logBlock(state);
    }
}

#pragma mark - PROPERTY

- (void)setCurrentCrashCountOnLaunch:(NSUInteger)currentCrashCountOnLaunch {
    _currentCrashCountOnLaunch = currentCrashCountOnLaunch;
    [self saveToLocalWithValue:@(_currentCrashCountOnLaunch) forKey:CURRENT_CRASH_COUNT_KEY];
}

- (void)setShallowRepairFinished:(BOOL)shallowRepairFinished {
    _shallowRepairFinished = shallowRepairFinished;
    [self saveToLocalWithValue:@(_shallowRepairFinished) forKey:SHALLOW_REPAIR_FINISHED_KEY];
}

- (void)setDeepRepairFinished:(BOOL)deepRepairFinished {
    _deepRepairFinished = deepRepairFinished;
    [self saveToLocalWithValue:@(_deepRepairFinished) forKey:DEEP_REPAIR_FINISHED_KEY];
}

- (void)setHotfixFinished:(BOOL)hotfixFinished {
    _hotfixFinished = hotfixFinished;
    [self saveToLocalWithValue:@(_hotfixFinished) forKey:HOTFIX_FINISHED_KEY];
}

@end
