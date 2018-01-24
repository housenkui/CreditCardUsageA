//
//  NSString+Extension.h
//  QLTools
//
//  Created by wangfaguo on 16/8/2.
//  Copyright © 2016年 wangfaguo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extension)

/**
 *  美化银行卡号，即每四位数字出现一个空格
 */

-(NSString *)ql_normalNumToBankNum;


/**
 * 美化银行卡号转换成正常模式
 */

-(NSString *)ql_bankNumToNormalNum;
/**
 * 去掉空格
 */

-(NSString *)ql_trimSpace;

/**
 * 金额 转换成 1,000,000.00 格式
 */

-(NSString *)ql_convertToMoneyMode;

/**
 *金额 转换成1 0000.00格式
 */

-(NSString *)ql_convertToFloatMode;

/**
 * md5加密
 */

-(NSString *)ql_md5;

/**
 * url拼接参数
 */

-(NSString*)ql_appendingUrlParams:(NSDictionary*)params;

@end
