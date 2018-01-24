//
//  NSString+Extension.m
//  QLTools
//
//  Created by wangfaguo on 16/8/2.
//  Copyright © 2016年 wangfaguo. All rights reserved.
//

#import "NSString+Extension.h"

#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Extension)
// 正常号转银行卡号 － 增加4位间的空格
-(NSString *)ql_normalNumToBankNum
{
    NSString *tmpStr = [self ql_bankNumToNormalNum];
    
    NSInteger size = (tmpStr.length / 4);
    
    NSMutableArray *tmpStrArr = [[NSMutableArray alloc] init];
    for (NSInteger n = 0;n < size; n++)
    {
        [tmpStrArr addObject:[tmpStr substringWithRange:NSMakeRange(n*4, 4)]];
    }
    
    [tmpStrArr addObject:[tmpStr substringWithRange:NSMakeRange(size*4, (tmpStr.length % 4))]];
    
    tmpStr = [tmpStrArr componentsJoinedByString:@" "];
    
    return tmpStr;
}

// 银行卡号转正常号 － 去除4位间的空格
-(NSString *)ql_bankNumToNormalNum
{
    return [self stringByReplacingOccurrencesOfString:@" " withString:@""];
}
//去掉空格
-(NSString*)ql_trimSpace{
    return [self stringByReplacingOccurrencesOfString:@" " withString:@""];
}

-(NSString *)ql_convertToMoneyMode{
    NSArray *array = [self componentsSeparatedByString:@"."];
    //数组空，返回自己
    if (!array) {
        return self;
    }
    NSString *string = [array objectAtIndex:0];
    NSMutableArray *tmpStrArr = [[NSMutableArray alloc] init];
    //字符串中有几个3位数
    NSInteger len = string.length / 3;
    //取余数
    NSInteger lest = string.length % 3;
    for (int i = 1; i <=len; i++) {
        NSString *subStr = [string substringWithRange:NSMakeRange(string.length - (i*3), 3)];
        [tmpStrArr insertObject:subStr atIndex:0];
    }
    if (lest > 0) {
        [tmpStrArr insertObject:[string substringWithRange:NSMakeRange(0, lest)] atIndex:0];
    }
    NSString *tempString = [tmpStrArr componentsJoinedByString:@","];
    //有小数
    if([array count] > 1){
        NSString *string = [array objectAtIndex:1];
        if (string.length >=2) {
            return [NSString stringWithFormat:@"%@.%@",tempString,[string substringWithRange:NSMakeRange(0, 2)]];
        }else{
            return [NSString stringWithFormat:@"%@.%@0",tempString,string];
        }
        
        
    }else{
        return [tempString stringByAppendingString:@".00"];
    }
    return tempString;
    
}
-(NSString *)ql_convertToFloatMode{
    NSArray *array = [self componentsSeparatedByString:@"."];
    //数组空，返回自己
    NSString *tempString = [NSString stringWithFormat:@"%@",array[0]];
    if (!array) {
        return self;
    }
    //有小数
    if([array count] > 1){
        NSString *string = [array objectAtIndex:1];
        if (string.length >=2) {
            return [NSString stringWithFormat:@"%@.%@",tempString,[string substringWithRange:NSMakeRange(0, 2)]];
        }else{
            return [NSString stringWithFormat:@"%@.%@0",tempString,string];
        }
        
    }else{
        return [tempString stringByAppendingString:@".00"];
    }
    return tempString;
}

-(NSString *)ql_md5
{
    const char *original_str = [self UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original_str, strlen(original_str), result);
    NSMutableString *hash = [NSMutableString string];
    for (int i = 0; i < 16; i++)
    [hash appendFormat:@"%02X", result[i]];
    return [hash lowercaseString];
}
-(NSString *)ql_appendingUrlParams:(NSDictionary *)params{
    //不是http 协议直接返回
    if ([self rangeOfString:@"http"].location == NSNotFound) {
        return self;
    }
    if ([self rangeOfString:@"?"].location == NSNotFound) {
        if ([params count] == 0) {
            return self;
        }
        NSString *fristKey = [[params allKeys]firstObject];
        NSString *firstObj = params[fristKey];
        if (!firstObj) {
            firstObj = @"";
        }
        NSMutableString *tempStr = [[NSMutableString alloc]initWithString:self];
        [tempStr appendFormat:@"?%@=%@",fristKey,firstObj];
        for (NSString *key in [params allKeys]) {
            if ([key isEqualToString:fristKey]) {
                continue;
            }
            NSString *obj = params[key];
            if (!obj) {
                obj = @"";
            }
            [tempStr appendFormat:@"&%@=%@",key,obj];
        }
        return tempStr;
    }else{
        NSMutableString *tempStr = [[NSMutableString alloc]initWithString:self];
        for (NSString *key in [params allKeys]) {
            NSString *obj = params[key];
            if (!obj) {
                obj = @"";
            }
            [tempStr appendFormat:@"&%@=%@",key,obj];
        }
        return tempStr;
    }
    
    return self;
}
@end
