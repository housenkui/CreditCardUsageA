//
//  QLBaseModel.h
//  TestProject
//
//  Created by zhouzhenghua on 16/7/4.
//  Copyright © 2016年 QianLong. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QLBaseModel : NSObject
/*
 以下三个方法是子类实现。
 */

- (NSDictionary *)QLPropertyDic;//存放属性值，规则:属性是键，服务端返回的键作为这个字典的值
- (NSDictionary *)QLArrayDic;//属性是个数组，数组里存放的是模型model
- (NSDictionary *)QLModelDic;//属性是个模型model,可能有多个模型，放在这里处理
@end
