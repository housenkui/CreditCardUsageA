//
//  QLBaseModel.m
//  TestProject
//
//  Created by zhouzhenghua on 16/7/4.
//  Copyright © 2016年 QianLong. All rights reserved.
//

#import "QLBaseModel.h"
@interface QLBaseModel()
@property (nonatomic,strong)NSDictionary *sourceDic;//源数据
@end
@implementation QLBaseModel

- (NSDictionary *)QLPropertyDic {
    
    return @{
       @"a_b_c":@"abc",//测试用
       @"d_e_f":@"def"
     };
    
}

- (NSDictionary *)QLArrayDic {
    return @{@"mySons": [QLBaseModel class]};//键写属性，值写数组里model的class
}
- (NSDictionary *)QLModelDic {
    return @{@"myMother" : [QLBaseModel class]};//键写属性，值写model的class
}

- (void)setValue:(id)value forKey:(NSString *)key {
    //这里处理value，再赋值
    if (value == nil || [value isEqual:[NSNull null]]) {
        value = self.sourceDic[key];
    }
    
    if ([value isKindOfClass:[NSNull class]]) {
        value = @"";
    }else {
        
        if (self.QLModelDic.count > 0 && [value isKindOfClass:[NSDictionary class]]) {
        
            Class ModelClass = [self.QLModelDic objectForKey:key];
            id middle = [ModelClass new];
            [middle setValuesForKeysWithDictionary:value];
            
            value  = middle;
            
        }else if(self.QLArrayDic.count > 0 && [value isKindOfClass:[NSArray class]]) {
            
            Class ModelClass = self.QLArrayDic[key];
            
            NSMutableArray *middleArr = @[].mutableCopy;
            [value enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                id middleClass = [ModelClass new];
                [middleClass setValuesForKeysWithDictionary:obj];
                [middleArr addObject:middleClass];
            }];
            
            value = middleArr;
            
        }else{
            value = [NSString stringWithFormat:@"%@",value];
        }
    }
    
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
    //嵌套model会导致value值为nil
    NSArray *keys = [self.QLPropertyDic allKeysForObject:key];
    NSString *propertyKey = nil;
    if (keys.count >0) {
        propertyKey = keys[0];
    }else {
        return;
    }
    
    NSLog(@"undefined key is %@, property key is %@ value is %@",key,propertyKey,value);
    if (propertyKey) {
        if (value == nil || [value isEqual:[NSNull null]]) {
            value = self.sourceDic[key];
        }
        [self setValue:value forKey:propertyKey];
        
    }else {
    //do nothing.这里不做任何事情
    }
    
}

- (void)setValuesForKeysWithDictionary:(NSDictionary<NSString *,id> *)keyedValues {
    self.sourceDic = keyedValues;
    [super setValuesForKeysWithDictionary:keyedValues];
}







@end
