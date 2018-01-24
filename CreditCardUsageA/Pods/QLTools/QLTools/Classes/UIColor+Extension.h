//
//  UIColor+Extension.h
//  QLTools
//
//  Created by wangfaguo on 16/8/2.
//  Copyright © 2016年 wangfaguo. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Extension)
/**
 * 16进制生成颜色，可设置透明度
 */
+ (UIColor*)ql_colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alphaValue;

/**
 * 16进制生成颜色，透明度为1.0
 */

+ (UIColor*)ql_colorWithHex:(NSInteger)hexValue;

/**
 *  颜色转换成16进制数据
 */

+ (NSString *)ql_hexFromUIColor: (UIColor*) color;

/**
 *  根据16进制字符串生成颜色， @"#002211"
 */

+(UIColor *)ql_colorWithHexString:(NSString *)hexString;

@end
