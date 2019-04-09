# EVLaunchProtection
一款App启动保护组件，防止App启动时连续崩溃。
- 内部原理: 设置一个App生存时间，如果App启动后，运行时间超过该时间，则认为启动正常；反之，则认为启动过程中，发生了崩溃错误；当崩溃次数超过设置的阈值时，执行浅度修复策略，具体策略行为，由用户自定义，当浅度修复策略 无法修复崩溃问题时，执行深度修复策略；同理，当深度修复策略无效时，最后执行热修复策略。 
> 一般策略行为主要包括：删除各种缓存，包括三方框架缓存，删除本地数据库，删除本地持久化数据，删除用户信息，删除热修复包(崩溃也可能是应用了热修复包引起的)，将本地所有相关资源恢复到初试状态等。
- 适用场景: 防止App启动连续崩溃，当监测到崩溃时，进行自我修复；
## Install with cocoapods
pod 'EVLaunchProtection', '~> 0.0.1'
## API
```
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 启动保护流程状态
 */
typedef NS_ENUM(NSUInteger, EVLaunchProtectionState) {
    EVLaunchProtectionStateNormal,                 //启动流程正常
    EVLaunchProtectionStateShallowRepairFinished,  //监测到崩溃，执行浅修复流程完毕
    EVLaunchProtectionStateShallowRepairSuccess,   //监测到崩溃，浅修复流程修复后，启动成功
    EVLaunchProtectionStateDeepRepairFinished,     //监测到崩溃，执行深度修复流程完毕
    EVLaunchProtectionStateDeepRepairSuccess,      //监测到崩溃，深度修复流程修复后，启动成功
    EVLaunchProtectionStateHotfixBefore,           //监测到崩溃，执行热修复之前
    EVLaunchProtectionStateHotfixFinished,         //监测到崩溃，执行热修复流程完毕
    EVLaunchProtectionStateHotfixSuccess,          //监测到崩溃，热修复流程修复后，启动成功
};

typedef void(^EVLaunchProtectionRepairBlock)(void);

typedef void(^EVLaunchProtectionHotfixFinishedBlock)(void);
typedef void(^EVLaunchProtectionHotfixBlock)(EVLaunchProtectionHotfixFinishedBlock hotfixFinishedBlock);

typedef void(^EVLaunchProtectionLogBlock)(EVLaunchProtectionState state);

@interface EVLaunchProtection : NSObject

/**
 App最小生存时间：如果小于该时间，则认为发生了启动crash。默认：6s。
 */
@property (nonatomic, assign) NSUInteger minAppLiveThreshold;

/**
 启动crash阈值；如果启动crash >= 该值，则执行浅度修复策略：shallowRepairBlock。默认：2.
 */
@property (nonatomic, assign) NSUInteger thresholdToShallowRepairWhenContinuousCrashOnLaunch;

/**
 启动crash阈值；如果启动crash >= 该值，则执行深度修复策略：deepRepairBlock。默认：3.
 */
@property (nonatomic, assign) NSUInteger thresholdToDeepRepairWhenContinuousCrashOnLaunch;

/**
 当前crash次数；如果App启动后，在 minAppLiveThreshold 时间内，发生了crash，则 +1.
 */
@property (nonatomic, assign, readonly) NSUInteger currentCrashCountOnLaunch;

/**
 浅度修复策略
 */
@property (nonatomic, copy) EVLaunchProtectionRepairBlock shallowRepairBlock;

/**
 深度修复策略；执行深度修复策略之前，内部默认会同时先执行一次浅度修复策略。
 */
@property (nonatomic, copy) EVLaunchProtectionRepairBlock deepRepairBlock;

/**
 执行热修复策略；当浅度修复策略和深度修复策略 修复无效时，执行热修复策略(内部默认会同时先执行一次浅度和深度修复策略)；可以在此回调中异步请求线上热修复包，内部会自动阻塞主线程，当修复完成后，需调用hotfixFinishedBlock。
 注意：hotFixBlock 会在异步线程中执行；如果需要切换主线程，请先调用 hotfixFinishedBlock，以解除对主线程的阻塞。
 */
@property (nonatomic, copy) EVLaunchProtectionHotfixBlock hotfixBlock;

/**
 日志回调
 */
@property (nonatomic, copy) EVLaunchProtectionLogBlock logBlock;

+ (instancetype)shared;

/**
 配置策略

 @param shallowRepairBlock 浅度修复策略
 @param deepRepairBlock 深度修复策略
 @param hotfixBlock 热修复策略
 @param logBlock 日志策略
 */
- (void)configureStrategyWithShallowRepair:(EVLaunchProtectionRepairBlock)shallowRepairBlock
                                deepRepair:(EVLaunchProtectionRepairBlock)deepRepairBlock
                                    hotfix:(EVLaunchProtectionHotfixBlock)hotfixBlock
                                       log:(EVLaunchProtectionLogBlock)logBlock;

/**
 开启保护
 */
- (void)start;

@end

NS_ASSUME_NONNULL_END

```

# 微信公众号 ：汪汪的世界
![(WeChat)](https://github.com/YongbaoWang/EverShowPath/blob/master/EverShowPath/wechat_num.jpg)
