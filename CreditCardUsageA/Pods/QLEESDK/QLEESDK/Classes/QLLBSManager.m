//
//  QLLBSManager.m
//  Pods
//
//  Created by wangfaguo on 16/11/22.
//
//

#import "QLLBSManager.h"
#import <MapKit/MapKit.h>
#include <ifaddrs.h>
#include <sys/socket.h> // Per msqr
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <netinet/in.h>

#define is_IOS8 ([[[[[UIDevice currentDevice] systemVersion] componentsSeparatedByString:@"."] objectAtIndex:0] intValue] >= 8)

@interface QLLBSManager() <MKMapViewDelegate,CLLocationManagerDelegate>

@property (nonatomic,strong) CLLocationManager *myLocationManager;
@property (nonatomic,strong) CLLocation *myLocation;
@property (nonatomic,strong,readwrite) NSString *longitude;
@property (nonatomic,strong,readwrite) NSString *latitude;
@property (nonatomic,strong,readwrite) NSString *province;
@property (nonatomic,strong,readwrite) NSString *city;
@property (nonatomic,strong,readwrite) NSString *district;
@property (nonatomic,strong) NSString *ipString;

+(instancetype)sharedInstance;

-(void)authorization;

@end


@implementation QLLBSManager
+(QLLBSManager *)shaerdInstance{
    static QLLBSManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[QLLBSManager alloc]init];
    });
    return sharedInstance;
}
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.longitude = @"";
        self.latitude = @"";
        self.province = @"";
        self.city = @"";
        self.district = @"";
        self.ipString = @"";
        self.myLocationManager = [[CLLocationManager alloc]init];
        self.myLocationManager.delegate = self;
        if (is_IOS8) {
            [self.myLocationManager requestWhenInUseAuthorization];
        }
        //选择定位的方式为最优的状态，他又四种方式在文档中能查到
        self.myLocationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
        //发生事件的最小距离间隔
        self.myLocationManager.distanceFilter = 1000.0f;
        [self.myLocationManager startUpdatingLocation];

    }
    return self;
}

#pragma mark -
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations{
    CLLocation *newLocation = [locations lastObject];
    [self.myLocationManager stopUpdatingLocation];
    NSLog(@"Latitude = %f", newLocation.coordinate.latitude);
    NSLog(@"Longitude = %f", newLocation.coordinate.longitude);
    self.latitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.latitude];
    self.longitude = [NSString stringWithFormat:@"%f",newLocation.coordinate.longitude];
    // 获取当前所在的城市名
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    //根据经纬度反向地理编译出地址信息
    [geocoder reverseGeocodeLocation:newLocation completionHandler:^(NSArray *array, NSError *error){
        if (array.count > 0){
            CLPlacemark *placemark = [array objectAtIndex:0];
            //将获得的所有信息显示到label上
            //获取城市
            NSString *province = placemark.administrativeArea;
            NSString *city = placemark.locality;
            NSString *district = placemark.subLocality;
            NSLog(@"placemark.administrativeArea = %@", placemark.administrativeArea);
            NSLog(@"placemark.subAdministrativeArea = %@", placemark.subAdministrativeArea);
            NSLog(@"province = %@", province);
            NSLog(@"city = %@", city);
            NSLog(@"subLocality = %@", district);
            
            self.province = province ?: @"";
            self.city = city ?: @"";
            self.district = district ?: @"";
        }
    }];
    
    self.myLocation = newLocation;


}
/*
 
 [_geocoder geocodeAddressString:address completionHandler:^(NSArray *placemarks, NSError *error) {
 //取得第一个地标，地标中存储了详细的地址信息，注意：一个地名可能搜索出多个地址
 CLPlacemark *placemark=[placemarks firstObject];
 
 CLLocation *location=placemark.location;//位置
 CLRegion *region=placemark.region;//区域
 NSDictionary *addressDic= placemark.addressDictionary;//详细地址信息字典,包含以下部分信息
 //        NSString *name=placemark.name;//地名
 //        NSString *thoroughfare=placemark.thoroughfare;//街道
 //        NSString *subThoroughfare=placemark.subThoroughfare; //街道相关信息，例如门牌等
 //        NSString *locality=placemark.locality; // 城市
 //        NSString *subLocality=placemark.subLocality; // 城市相关信息，例如标志性建筑
 //        NSString *administrativeArea=placemark.administrativeArea; // 州
 //        NSString *subAdministrativeArea=placemark.subAdministrativeArea; //其他行政区域信息
 //        NSString *postalCode=placemark.postalCode; //邮编
 //        NSString *ISOcountryCode=placemark.ISOcountryCode; //国家编码
 //        NSString *country=placemark.country; //国家
 //        NSString *inlandWater=placemark.inlandWater; //水源、湖泊
 //        NSString *ocean=placemark.ocean; // 海洋
 //        NSArray *areasOfInterest=placemark.areasOfInterest; //关联的或利益相关的地标
 NSLog(@"位置:%@,区域:%@,详细信息:%@",location,region,addressDic);
 }];
 
 */
-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status{
    switch (status) {
        case kCLAuthorizationStatusAuthorized:
            NSLog(@"此应用授权了");
            break;
        case kCLAuthorizationStatusDenied:
        {
            NSLog(@"没有授权");
        }
            
            break;
        case kCLAuthorizationStatusRestricted:
            break;
        case kCLAuthorizationStatusNotDetermined:
            NSLog(@"");
            break;
        default:
            break;
    }
    
}
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    NSLog(@"%@",[error description]);
    
}

+(NSString*)getIPAddress{
    UInt32 address = 0;
    struct ifaddrs *interfaces;
    if( getifaddrs(&interfaces) == 0 ) {
        struct ifaddrs *interface;
        for( interface=interfaces; interface; interface=interface->ifa_next ) {
            if( (interface->ifa_flags & IFF_UP) && ! (interface->ifa_flags & IFF_LOOPBACK) ) {
                const struct sockaddr_in *addr = (const struct sockaddr_in*) interface->ifa_addr;
                if( addr && addr->sin_family == AF_INET ) {
                    address = addr->sin_addr.s_addr;
                    break;
                }
            }
        }       freeifaddrs(interfaces);
    }
    if(address != 0 ) {
        const UInt8* addrBytes = (const UInt8*)&address;
        return [NSString stringWithFormat: @"%u.%u.%u.%u",(unsigned)addrBytes[0],(unsigned)addrBytes[1],(unsigned)addrBytes[2],(unsigned)addrBytes[3]];
    }
    return @"";
}


@end
