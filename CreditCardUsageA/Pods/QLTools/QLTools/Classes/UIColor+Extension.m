//
//  UIColor+Extension.m
//  QLTools
//
//  Created by wangfaguo on 16/8/2.
//  Copyright © 2016年 wangfaguo. All rights reserved.
//

#import "UIColor+Extension.h"

@implementation UIColor (Extension)
+ (UIColor*)ql_colorWithHex:(NSInteger)hexValue alpha:(CGFloat)alphaValue
{
    return [UIColor colorWithRed:((float)((hexValue & 0xFF0000) >> 16))/255.0
                           green:((float)((hexValue & 0xFF00) >> 8))/255.0
                            blue:((float)(hexValue & 0xFF))/255.0 alpha:alphaValue];
}

+ (UIColor*)ql_colorWithHex:(NSInteger)hexValue
{
    return [UIColor ql_colorWithHex:hexValue alpha:1.0];
}

+ (NSString *)ql_hexFromUIColor: (UIColor*) color {
    if (CGColorGetNumberOfComponents(color.CGColor) < 4) {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        color = [UIColor colorWithRed:components[0]
                                green:components[0]
                                 blue:components[0]
                                alpha:components[1]];
    }
    
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) != kCGColorSpaceModelRGB) {
        return [NSString stringWithFormat:@"#FFFFFF"];
    }
    
    return [NSString stringWithFormat:@"#%x%x%x", (int)((CGColorGetComponents(color.CGColor))[0]*255.0),
            (int)((CGColorGetComponents(color.CGColor))[1]*255.0),
            (int)((CGColorGetComponents(color.CGColor))[2]*255.0)];
}


+(UIColor *)ql_colorWithHexString:(NSString *)hexString {
    
    NSString *color = [hexString stringByReplacingOccurrencesOfString:@"#" withString:@""];
    color = [color stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    color = [NSString stringWithFormat:@"0x%@",color];
    //先以16为参数告诉strtoul字符串参数表示16进制数字，然后使用0x%X转为数字类型
    unsigned long colorHex = strtoul([color UTF8String],0,16);
    return [UIColor ql_colorWithHex:colorHex];
    
}

@end
