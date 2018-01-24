//
//  QLEESDK.h
//  Pods
//
//  Created by wangfaguo on 16/8/19.
//
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

typedef NS_ENUM(NSInteger,QLEEActionType) {
    QLEEActionClick = 0,//点击动作
    QLEEActionInput,//输入动作
    QLEEActionSlide,//滑动动作，
    QLEEActionOPen,//app启动
    QLEEActionClose,//app关闭
};

@interface QLEESDK : NSObject


/*
 * 设置服务地址，默认：@"https://eeopenapi.shoujidai.com"
 * @address 服务地址
 * @目前测试地址：@"http://192.168.1.125:60008"
 */

+(void)setServerAddress:(NSString*)address;


/*
 *
 * @productName 产品标示 比如："shoujidai"
 * @debugMode 调试模式
 * @interval发送时间间隔 单位：秒 ，默认60秒
 * @bulkSize每次发送的条数 ,默认 10条
 * @market 下载市场
 */

+(void)startWithProductName:(NSString *)productName
               andDebugMode:(BOOL)debugMode
                andBulkSize:(NSInteger)bulkSize
           andFlushInterval:(CGFloat)interval
                   andMarket:(NSString*)market;

/*
 * 监控事件，
 * event 业务方定义的事件名称
 * action 动作类型
 * properties 业务方约定好的数据
 */

+(void)trackEvent:(NSString*)event action:(QLEEActionType)action properties:(NSDictionary*)properties;

// 监控事件的便捷方法，即properties为空

+(void)trackEvent:(NSString*)event action:(QLEEActionType)action;

//监控用户注册 ，distinctId填userid，注册后调用此方法，

+(void)userRegisterEvent:(NSString *)event distinctId:(NSString *)distinctId properties:(NSDictionary *)properties;
//监控用户登录 ，distinctId填userid，登录后调用此方法，
+(void)userLoginEvent:(NSString *)event distinctId:(NSString *)distinctId properties:(NSDictionary *)properties;

//用户退出
+(void)logout;

/*
 * 进入页面的事件
 */

+(void)beginWithPage:(NSString*)page;

/*
 * 离开页面的事件
 */

+(void)endWithPage:(NSString*)page;

//强制发送 (不推荐)
+(void)flush;

@end
