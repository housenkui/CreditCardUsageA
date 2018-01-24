//
//  QLLBSManager.h
//  Pods
//
//  Created by wangfaguo on 16/11/22.
//
//

#import <Foundation/Foundation.h>

@interface QLLBSManager : NSObject

@property (nonatomic,strong,readonly) NSString *longitude;
@property (nonatomic,strong,readonly) NSString *latitude;
@property (nonatomic,strong,readonly) NSString *province;
@property (nonatomic,strong,readonly) NSString *city;
@property (nonatomic,strong,readonly) NSString *district;
+(QLLBSManager*)shaerdInstance;

+(NSString*)getIPAddress;

@end
