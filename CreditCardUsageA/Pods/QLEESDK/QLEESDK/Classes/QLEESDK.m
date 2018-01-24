//
//  QLEESDK.m
//  Pods
//
//  Created by wangfaguo on 16/8/19.
//
//

#import "QLEESDK.h"
#import <UIKit/UIKit.h>
#import <sys/utsname.h>
#import <AdSupport/AdSupport.h>
#import <AFNetworking/AFNetworking.h>
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import "QLLBSManager.h"



#define ee_trackEvent @"eagleeye/ubt/trackEvent" //事件监控接口
#define ee_trackSignup @"eagleeye/ubt/trackSignup" //注册事件监控接口
#define ee_trackEventByBatch @"eagleeye/ubt/trackEventByBatch" //事件监控接口，批量提交
#define ee_eagleEyeMonitorLogEvent @"eagleeye/monitor/logEvent" //崩溃收集
#define ee_Params  @"body"
#define ee_crashInfoContent @"ee_crashInfoContent"


@class NdUncaughtExceptionHandler;

void SignalHandler(int signal);
void InstallUncaughtExceptionHandler(void);

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";

NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";

NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

volatile int32_t UncaughtExceptionCount = 0;

const int32_t UncaughtExceptionMaximum = 10;

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;

const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;



#pragma mark - QLEEItem

/**
 *  监控对象
 */

//后期可设计
//公共属性添加，App 版本、网络状态、IP、设备型号等一系列系统信息做为事件属性

@interface QLEEItem : NSObject

@property (nonatomic,strong) NSString *domain; //项目名
@property (nonatomic,strong) NSString *distinctId;
@property (nonatomic,strong) NSString *orginalId;
@property (nonatomic,strong) NSString *timestamp;
@property (nonatomic,strong) NSString *action;
@property (nonatomic,strong) NSString *event;
@property (nonatomic,strong) NSMutableDictionary *properties;

@property (nonatomic,strong) QLLBSManager *lbsManager;

@end


@implementation QLEEItem

- (instancetype)init
{
    self = [super init];
    if (self) {
       self.timestamp = [[self class] getTimeStamp];
        CGFloat screen_width = [[UIScreen mainScreen] currentMode].size.width;
        CGFloat screen_height = [[UIScreen mainScreen] currentMode].size.height;
        NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
//        NSString *systemName = [[UIDevice currentDevice] systemName];
        NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
        NSString *model = [[UIDevice currentDevice] model];
        NSDictionary *dic = @{@"$manufacturer":@"Apple",
                              @"$model":model,
                              @"$os":@"iOS",
                              @"$os_version":systemVersion,
                              @"$app_version":appVersion,
                              @"$screen_width":[NSString stringWithFormat:@"%0.0f",screen_width],
                              @"$screen_height":[NSString stringWithFormat:@"%0.0f",screen_height],
                              };
        self.properties = [[NSMutableDictionary alloc]initWithDictionary:dic];
    }
    return self;
}
//定位是需要时间的，所以延迟添加
-(void)addLBS{
    NSDictionary *lbsDic = @{
                             @"$longitude":[QLLBSManager shaerdInstance].longitude,
                             @"$latitude":[QLLBSManager shaerdInstance].latitude,
                             @"$ip":[QLLBSManager getIPAddress],
                             @"$province":[QLLBSManager shaerdInstance].province,
                             @"$city":[QLLBSManager shaerdInstance].city,
                             @"$district":[QLLBSManager shaerdInstance].district};
    [self.properties addEntriesFromDictionary:lbsDic];
}
+(NSString*)getTimeStamp{
    NSDate *date = [NSDate date];
    NSTimeInterval timeInterval = [date timeIntervalSince1970];
    return [NSString stringWithFormat:@"%0.0f",timeInterval*1000];
}
//对象数据转换成字典
-(NSDictionary*)data{
    return @{@"domain":self.domain,
             @"distinctId":self.distinctId,
             @"orginalId":self.orginalId,
             @"timestamp":self.timestamp,
             @"action":self.action,
             @"event":self.event,
             @"properties":self.properties};
}

@end

#pragma mark - QLEESDK

static QLEESDK *sharedInstance = nil;
static NSString *ee_server_name = @"https://eeopenapi.shoujidai.com";

//
@interface QLEESDK()
{
    dispatch_queue_t timerQueue;
    dispatch_source_t _timerSource;
    
}

@property (nonatomic,strong) NSString *serverUrl;//服务器ip
@property (nonatomic,strong) NSString *domainName;//产品名
@property (nonatomic,assign) BOOL debug;//调试模式
@property (nonatomic,strong) NSMutableArray *events;//事件队列
@property (nonatomic, strong) AFHTTPSessionManager *sessionManager; //网络请求
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic,strong) NSString *userId;//用户未登录时，赋值idfa，用户登录后，赋值userid
@property (nonatomic,assign) CGFloat  flushInterval; //多少秒发送一次
@property (nonatomic,assign) NSInteger  flushBulkSize;//每次发送的条数
@property (nonatomic,strong) NSString *market; //下载市场
@property (nonatomic,assign) BOOL isUploading;//是否正在上传中
@property (nonatomic,strong) NSCondition *eventslock;


+ (NSArray *)backtrace;

@end

@implementation QLEESDK

+(void)setServerAddress:(NSString *)address{
    ee_server_name = address ?: @"https://eeopenapi.shoujidai.com";
}

+(instancetype)sharedInstanceWithBulkSize:(NSInteger)bulkSize andFlushInterval:(CGFloat)interval andMarket:(NSString*)market{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[QLEESDK alloc]initWithBulkSize:bulkSize andFlushInterval:interval andMarket:market];
    });
    return sharedInstance;
}


- (instancetype)initWithBulkSize:(NSInteger)bulkSize andFlushInterval:(CGFloat)interval andMarket:(NSString*)market
{
    self = [super init];
    if (self) {
        InstallUncaughtExceptionHandler();
        self.serverUrl = ee_server_name;
        self.debug = NO;
        self.events = [[NSMutableArray alloc]init];
        self.flushBulkSize = bulkSize ?: 10;
        self.flushInterval = interval ?: 60.;
        self.market = market?:@"appstore";
        self.eventslock = [[NSCondition alloc]init];//锁
        
        NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"QLEESDK" ofType:@"bundle"]];
        //安全策略
        AFSecurityPolicy *security = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey withPinnedCertificates:[[self class] certificatesInBundle:bundle]];
        security.allowInvalidCertificates = YES;
        
        self.sessionManager = [[AFHTTPSessionManager alloc]initWithBaseURL:nil sessionConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        self.sessionManager.securityPolicy = security;
        self.sessionManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        AFHTTPRequestSerializer *requestSerializer = [AFHTTPRequestSerializer serializer];
        requestSerializer.timeoutInterval = 30;
//        

        //程序将要推出的通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillTerminateNotification) name:UIApplicationWillTerminateNotification object:nil];
        //程序变成激活状态的通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [self startTimer];
        
        //开始定位
        [QLLBSManager shaerdInstance];
        
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationWillTerminateNotification object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

#pragma mark - public method

-(void)monitorInternetWork{
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
            {
                
            }
                break;
            case AFNetworkReachabilityStatusNotReachable:
            {
                
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
            {
                
            }
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
            {
                
            }
                break;
            default:
                break;
        }
    }];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

+(void)startWithProductName:(NSString *)productName andDebugMode:(BOOL)debugMode andBulkSize:(NSInteger)bulkSize andFlushInterval:(CGFloat)interval andMarket:(NSString *)market{
    sharedInstance = [QLEESDK sharedInstanceWithBulkSize:bulkSize andFlushInterval:interval andMarket:market];
    sharedInstance.domainName = productName?:@"";
    sharedInstance.debug = debugMode;
}

+(void)trackEvent:(NSString *)event action:(QLEEActionType)action{
    [[self class] trackEvent:event action:action properties:nil];
}

+(void)trackEvent:(NSString *)event action:(QLEEActionType)action properties:(NSDictionary *)properties{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QLEEItem *item = [[QLEEItem alloc]init];
        item.domain = sharedInstance.domainName?:@"";
        switch (action) {
            case QLEEActionClick:
                item.action = @"click";
                break;
            case QLEEActionInput:
                item.action = @"input";
                break;
            case QLEEActionSlide:
                item.action = @"slide";
                break;
            case QLEEActionOPen:
                item.action = @"open";
                break;
            case QLEEActionClose:
                item.action = @"close";
                break;
            default:
                item.action = @"";
                break;
        }
        item.event = event?:@"";
        item.distinctId = sharedInstance.userId ?: [[self class]idfaString];
        item.orginalId = [[self class]idfaString];
        [item addLBS];
        [item.properties addEntriesFromDictionary:@{@"$market":sharedInstance.market}];
        if (properties) {
         [item.properties addEntriesFromDictionary:properties];
        }
        [sharedInstance.eventslock lock];
        [sharedInstance.events addObject:item];
        [sharedInstance.eventslock unlock];
        
        if (sharedInstance.debug) {
            NSLog(@"QLEESDK userEvent = %@",[item data]);
        }
    });
}

+(void)userRegisterEvent:(NSString *)event distinctId:(NSString *)distinctId properties:(NSDictionary *)properties{
    [QLEESDK userEvent:event action:@"$signup" distinctId:distinctId properties:properties];
}

+(void)userLoginEvent:(NSString *)event distinctId:(NSString *)distinctId properties:(NSDictionary *)properties{
    [QLEESDK userEvent:event action:@"$signin" distinctId:distinctId properties:properties];
}

+(void)userEvent:(NSString *)event action:(NSString*)action distinctId:(NSString *)distinctId properties:(NSDictionary *)properties{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAssert(distinctId != nil, @"userid can not be nil");
        //监控对象
        QLEEItem *item = [[QLEEItem alloc]init];
        item.domain = sharedInstance.domainName?:@"";
        item.action = action;
        item.event = event?:@"用户注册";
        item.distinctId = distinctId?:[[self class]idfaString];
        item.orginalId = [[self class]idfaString];
        [item addLBS];
        [item.properties addEntriesFromDictionary:@{@"$market":sharedInstance.market}];
        if (properties) {
          [item.properties addEntriesFromDictionary:properties];
        }
        sharedInstance.userId = distinctId;
        sharedInstance.debug ? NSLog(@"QLEESDK userRegisterEvent = %@",[item data]):nil;
        
        NSString *host = sharedInstance.serverUrl;
        if (![host hasPrefix:@"http://"] || ![host hasPrefix:@"https://"]) {
            NSAssert(host != nil, @"QLEESDK server not be a http url");
        }
        //注册事件上传
        NSString *url = [NSString stringWithFormat:@"%@/%@",host,ee_trackSignup];
        [QLEESDK uploadDataWithUrl:url andData:[item data] completion:^(NSInteger httpCode) {
            if (httpCode == 200) {
                
            }
        }];
    });
}
//封装的提交数据的方法
+(void)uploadDataWithUrl:(NSString*)url andData:(id)data completion:(void(^)(NSInteger httpCode))block{
    NSData *crashData = [[self class] toJSONData:data];
    if (!crashData) {
        return;
    }
    NSString *jsonString = [[NSString alloc] initWithData:crashData encoding:NSUTF8StringEncoding];
    NSMutableURLRequest *req = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:[NSString stringWithFormat:url] parameters:nil error:nil];
    [req setValue:@"text/html" forHTTPHeaderField:@"Content-Type"];
    [req setValue:@"text/html" forHTTPHeaderField:@"Accept"];
    [req setHTTPBody:[jsonString dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLSessionDataTask *task =  [sharedInstance.sessionManager dataTaskWithRequest:req completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
        NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
        NSLog(@"url = %@ , http code = %ld  error = %@",url,resp.statusCode,error);
        NSInteger statusCode = resp.statusCode;
            block(resp.statusCode);
       
    }];
    [task resume];
}
+(void)logout{
   sharedInstance.userId = nil;
}

+(void)beginWithPage:(NSString *)page{

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QLEEItem *item = [[QLEEItem alloc]init];
        item.domain = sharedInstance.domainName?:@"";
        item.action = @"goin";
        item.event = page?:@"";
        item.distinctId = sharedInstance.userId ?: [[self class]idfaString];
        item.orginalId = [[self class]idfaString];
        [item addLBS];
        [item.properties addEntriesFromDictionary:@{@"$market":sharedInstance.market}];
        [sharedInstance.eventslock lock];
        [sharedInstance.events addObject:item];
        [sharedInstance.eventslock unlock];
    });
   
}

+(void)endWithPage:(NSString *)page{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        QLEEItem *item = [[QLEEItem alloc]init];
        item.domain = sharedInstance.domainName?:@"";
        item.action = @"goto";
        item.event =  page?:@"";
        item.distinctId = sharedInstance.userId ?: [[self class]idfaString];
        item.orginalId = [[self class]idfaString];
        [item addLBS];
        [item.properties addEntriesFromDictionary:@{@"$market":sharedInstance.market}];
        [sharedInstance.eventslock lock];
        [sharedInstance.events addObject:item];
        [sharedInstance.eventslock unlock];
    });
    
}

+(void)setFlushInterval:(CGFloat)interval{
    sharedInstance.flushInterval = interval;
}

+(void)setFlushBulkSize:(NSInteger)flushBulkSize{
    sharedInstance.flushBulkSize = flushBulkSize;
}

+(void)flush{
    
    [sharedInstance uploadAllEvents];
}

//保存数据
+(void)saveEvents{
    [sharedInstance.eventslock lock];
    NSArray *data = [QLEESDK eeDataToArray:sharedInstance.events];
    [sharedInstance.eventslock unlock];
    [QLEESDK saveEEData:data file:[QLEEItem getTimeStamp]];
}

#pragma mark - notification
//程序退出的时候 保存没有发送的数据，下次启动再发送
-(void)applicationWillTerminateNotification{
    NSLog(@"applicationWillTerminateNotification ");
    //程序关闭的时候保存报文
    [QLEESDK saveEvents];
}
//程序激活的时候，这里可以处理一些事情，比如发送上次没有发送的数据
-(void)applicationDidBecomeActiveNotification{
    NSString *path = [[self class] getEEDataPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *contents = [fileManager contentsOfDirectoryAtPath:path error:NULL];
    NSEnumerator *e = [contents objectEnumerator];
    NSString *fileName;
     NSString *host = sharedInstance.serverUrl;
    while ((fileName = [e nextObject])) {
        NSArray * dataArray = [NSArray arrayWithContentsOfFile:[path stringByAppendingPathComponent:fileName]];
        if (!dataArray || [dataArray count] == 0) {
            continue;
        }
        NSLog(@"path = %@",[path stringByAppendingPathComponent:fileName]);
        NSString *url = [NSString stringWithFormat:@"%@/%@",host,ee_trackEventByBatch];
        NSLog(@"data array = %@",dataArray);
        //提交报文，成功则删除本地文件
        [QLEESDK uploadDataWithUrl:url andData:dataArray completion:^(NSInteger httpCode) {
            if (httpCode == 200) {
                 [fileManager removeItemAtPath:[path stringByAppendingPathComponent:fileName] error:NULL];
            }
        }];
    }
    
    //提交崩溃信息
    
    NSString *crashPath = [NSString stringWithFormat:@"%@/%@",[[self class] getEECrashDataPath],ee_crashInfoContent];
    NSLog(@"crashPath = %@",crashPath);
//    NSString *crashContent = [NSString stringWithContentsOfFile:crashPath encoding:NSUTF8StringEncoding error:nil];
    NSDictionary *crashDic = [[NSDictionary alloc]initWithContentsOfFile:crashPath];
    NSLog(@"crashDic = %@",crashDic);
    if (!crashDic) {
        return;
    }
    NSString *url = [NSString stringWithFormat:@"%@/%@",host,ee_eagleEyeMonitorLogEvent];
    [QLEESDK uploadDataWithUrl:url andData:crashDic completion:^(NSInteger httpCode) {
        if (httpCode == 200) {
            [fileManager removeItemAtPath:crashPath error:NULL];
        }
    }];
    
}
#pragma mark - private methods

+ (NSSet *)certificatesInBundle:(NSBundle *)bundle {
    NSArray *paths = [bundle pathsForResourcesOfType:@"cer" inDirectory:@"."];
    
    NSMutableSet *certificates = [NSMutableSet setWithCapacity:[paths count]];
    for (NSString *path in paths) {
        NSData *certificateData = [NSData dataWithContentsOfFile:path];
        [certificates addObject:certificateData];
    }
    
    return [NSSet setWithSet:certificates];
}

-(void)startTimer{
    
    /**
     * 开启一个线程，定时上传数据
     */
    /// 初始化一个timerQueue队列.
    timerQueue = dispatch_queue_create("timerQueue", DISPATCH_QUEUE_SERIAL);
    /// 创建 gcd timer.
    _timerSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue);
    double interval = self.flushInterval * NSEC_PER_SEC; /// 间隔60秒
    dispatch_source_set_timer(_timerSource, dispatch_time(DISPATCH_TIME_NOW, 0), interval, 0);
    /// 定时器block设置
    dispatch_source_set_event_handler(_timerSource, ^{
        
        NSString *host = self.serverUrl;
        NSString *url = [NSString stringWithFormat:@"%@/%@",host,ee_trackEventByBatch];
        NSArray *events = self.events;
        NSArray *eventsToSubmit;
        
        if ([events count] <= 0) {
            return ;
        }
        NSInteger numPerTime = self.flushBulkSize;
        if ([events count] > numPerTime) {
            eventsToSubmit = [[NSArray alloc]initWithArray:[events subarrayWithRange:NSMakeRange(0, numPerTime)]];
        }else{
            numPerTime = [events count];
            eventsToSubmit = [[NSArray alloc]initWithArray:events];
        }
        //如果下次循环到了，上传的请求还在，则跳过
        if (self.isUploading) {
            return;
        }
        self.isUploading = YES;
        //提交报文，成功则删除本地文件
        [QLEESDK uploadDataWithUrl:url andData:[QLEESDK eeDataToArray:eventsToSubmit] completion:^(NSInteger httpCode) {
            self.isUploading = NO;
            if (httpCode == 200) {
                //删除上传完的
                [self.eventslock lock];
                [self.events removeObjectsInRange:NSMakeRange(0, numPerTime)];
                [self.eventslock unlock];
            }
        }];
        
    });
    
    /// 唤起定时器任务.
    dispatch_resume(_timerSource);
}

-(void)uploadAllEvents{
//    挂起定时器
    dispatch_suspend(_timerSource);
    NSString *url = [NSString stringWithFormat:@"%@/%@",self.serverUrl,ee_trackEventByBatch];
    NSLog(@"events = %@",self.events);
    [QLEESDK uploadDataWithUrl:url andData:[QLEESDK eeDataToArray:self.events] completion:^(NSInteger httpCode) {
        if (httpCode == 200) {
            //删除上传完的
            [self.events removeAllObjects];
            //开启定时器
            dispatch_resume(_timerSource);
        }
    }];
}

//对象转换成字典
+(NSArray*)eeDataToArray:(NSArray*)items{
    
    NSMutableArray *tempArray = [[NSMutableArray alloc]init];
    for (QLEEItem *item in items) {
        [tempArray addObject:[item data]];
        [sharedInstance debug]? NSLog(@"QLEEItem items = %@",[item data]):nil;
    }
    return tempArray;
}
//保存数据
+(BOOL)saveEEData:(id)data file:(NSString*)fileName{
    NSString *dirPath = [[self class] getEEDataPath];
    BOOL dic;
    NSString *filePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&dic] && dic) {
        filePath = [NSString stringWithFormat:@"%@/%@",dirPath,fileName];
    }else{
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:Nil error:nil];
        filePath = [NSString stringWithFormat:@"%@/%@",dirPath,fileName];
    }
    BOOL result = [data writeToFile:filePath atomically:YES];
    if (result) {
        [sharedInstance debug]? NSLog(@"QLEEItem save success = %@",filePath):nil;
    }else{
       [sharedInstance debug]? NSLog(@"QLEEItem save fail = %@",filePath):nil;
    }
    return  result;
}
//报文保存的路径
+(NSString *)getEEDataPath{
    NSString *filePath = [NSString stringWithFormat:@"%@/QLEEDATA",[[self class] getDocumentsPath]];
    return filePath;
}
//崩溃信息保存的路径
+(NSString *)getEECrashDataPath{
    NSString *filePath = [NSString stringWithFormat:@"%@/QLEECrashDATA",[[self class] getDocumentsPath]];
    return filePath;
}
//NSDocumentDirectory 路径
+(NSString*)getDocumentsPath{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docPath = [paths objectAtIndex:0];
    return docPath;
}
//把对象转成字符串
+(NSString*)stringEscape:(id)obj{
    NSString *contacts = [[NSString alloc]initWithData:[[self class] toJSONData:obj] encoding:NSUTF8StringEncoding];
    return [[[contacts stringByReplacingOccurrencesOfString:@"\n" withString:@""] stringByReplacingOccurrencesOfString:@"\t" withString:@""] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
}

+(NSData *)toJSONData:(id)theData{
    
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:theData
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    
    if ([jsonData length] != 0 && error == nil){
        return jsonData;
    }else{
        return nil;
    }
}

+ (NSString *)idfaString {
    
    return [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString]?:@"";
}

-(NSString*)machineName{
    
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *result = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
    return result;
    
}


@end


@interface NdUncaughtExceptionHandler : NSObject {
    
}

+ (void)setDefaultHandler;
+ (NSUncaughtExceptionHandler*)getHandler;

@end

NSString *applicationDocumentsDirectory() {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

void UncaughtExceptionHandler(NSException *exception) {
    [QLEESDK saveEvents];
    
    NSArray *arr = [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    NSString *stacks = [arr componentsJoinedByString:@"\n"];
    NSString *crashMessage = [NSString stringWithFormat:@"%@\n%@",reason,stacks];
    
    NSString *domain = sharedInstance.domainName;
    NSString *timestamp = [QLEEItem getTimeStamp];
    NSDictionary *messageDic = [[NSDictionary alloc]initWithObjectsAndKeys:domain,@"domain",@"Event",@"messageType",@"Exception",@"type",name?:@"",@"name",crashMessage,@"nameValuePairs",timestamp,@"timestamp", nil];
    NSDictionary *data = [[NSDictionary alloc]initWithObjectsAndKeys:domain,@"domain",messageDic,@"message", nil];
    NSString *dirPath = [QLEESDK getEECrashDataPath];
    BOOL dic;
    NSString *filePath;
    if ([[NSFileManager defaultManager] fileExistsAtPath:dirPath isDirectory:&dic] && dic) {
        filePath = [NSString stringWithFormat:@"%@/%@",dirPath,ee_crashInfoContent];
    }else{
        [[NSFileManager defaultManager] createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:Nil error:nil];
        filePath = [NSString stringWithFormat:@"%@/%@",dirPath,ee_crashInfoContent];
    }
    BOOL result = [data writeToFile:filePath atomically:YES];
    result?NSLog(@"crash info save success %@ ",data):nil;

}

@implementation NdUncaughtExceptionHandler
+ (NSArray *)backtrace

{
    
    void* callstack[128];
    
    int frames = backtrace(callstack, 128);
    
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    
    for (
         
         i = UncaughtExceptionHandlerSkipAddressCount;
         
         i < UncaughtExceptionHandlerSkipAddressCount +
         
         UncaughtExceptionHandlerReportAddressCount;
         
         i++)
        
    {
        
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
        
    }
    
    free(strs);
    
    return backtrace;
    
}

-(NSString *)applicationDocumentsDirectory {
    return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
}

+ (void)setDefaultHandler
{
    NSSetUncaughtExceptionHandler (&UncaughtExceptionHandler);
}

+ (NSUncaughtExceptionHandler*)getHandler
{
    return NSGetUncaughtExceptionHandler();
}


void InstallUncaughtExceptionHandler(void)
{
    [NdUncaughtExceptionHandler setDefaultHandler];
    
    signal(SIGHUP, SignalHandler);
    signal(SIGINT, SignalHandler);
    signal(SIGQUIT, SignalHandler);
    
    signal(SIGABRT, SignalHandler);
    signal(SIGILL, SignalHandler);
    signal(SIGSEGV, SignalHandler);
    signal(SIGFPE, SignalHandler);
    signal(SIGBUS, SignalHandler);
    signal(SIGPIPE, SignalHandler);
}

void SignalHandler(int signal)
{
    [QLEESDK saveEvents];
    
    // 获取信息
    NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal] forKey:UncaughtExceptionHandlerSignalKey];
    
    NSArray *callStack = [NdUncaughtExceptionHandler backtrace];
    [userInfo  setObject:callStack  forKey:UncaughtExceptionHandlerAddressesKey];
    
    // 现在就可以保存信息到本地［］
    NSLog(@"SignalHandler = %@",userInfo);
}

@end

