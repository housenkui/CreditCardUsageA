//
//  QLFileSaveManager.h
//  TestProject
//
//  Created by zhouzhenghua on 16/8/2.
//  Copyright © 2016年 QianLong. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kQLSandboxDocument  [QLFileSaveManager pathForDocument]
#define kQLSandboxCach      [QLFileSaveManager pathForCach]



@interface QLFileSaveManager : NSObject
/*
*总则，filePath是文件的完整路径，比如@"/user/../parameter.plist"
 */

/*
 *parameters 数组
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */

+ (BOOL)saveArray:(NSArray *)parameters saveToPath:(NSString *)filePath;
/*
 *目标：对已经存在的数据进行追加
 *parameters 数组
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */
+ (BOOL)addToArray:(NSArray *)parameters saveToPath:(NSString *)filePath;
/*
 *parameters ，字典
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */
+ (BOOL)saveDictionary:(NSDictionary *)parameters saveToPath:(NSString *)filePath;

/*
 *parameters NSData
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */
+ (BOOL)saveData:(NSData *)parameters saveToPath:(NSString *)filePath;


/*
 *获取数组
 *filePath 文件路径
 */
+ (NSArray *)getArrayAtPath:(NSString *)filePath;

/*
 *获取字典
 *filePath 文件路径
 */
+ (NSDictionary *)getDictionaryAtPath:(NSString *)filePath;

/*
 *获取Data
 *filePath 文件路径
 */
+ (NSData *)getDataAtPath:(NSString *)filePath;


/*
 *删除文件
 *filePath 文件路径
 */

+ (BOOL)removeFileOfPath:(NSString *)filePath;

/*
 *沙盒document路径
 */
+ (NSString *)pathForDocument;
/*
 *沙盒cach路径
 */
+ (NSString *)pathForCach;




@end
