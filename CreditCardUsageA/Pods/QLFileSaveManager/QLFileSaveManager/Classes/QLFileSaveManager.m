//
//  QLFileSaveManager.m
//  TestProject
//
//  Created by zhouzhenghua on 16/8/2.
//  Copyright © 2016年 QianLong. All rights reserved.
//

#import "QLFileSaveManager.h"

@implementation QLFileSaveManager

/*
 *parameters 可以是数组
 *filePath  储存数据文件路径
 */

+ (BOOL)saveArray:(NSArray *)parameters saveToPath:(NSString *)filePath {
    if (!parameters || !filePath) {
        NSLog(@"存储文件路径或者数据为空");
        return NO;
    }
    
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSString *lastPathComponentDelete = [filePath stringByDeletingLastPathComponent];
    NSLog(@"value is %@",lastPathComponentDelete);
    if (![fileM fileExistsAtPath:lastPathComponentDelete]) {
        NSError *createError = nil;
        if (![fileM createDirectoryAtPath:lastPathComponentDelete withIntermediateDirectories:YES attributes:nil error:&createError]) {
            NSLog(@"创建目标路径失败 %@",createError.description);
            return NO;
        };
    }
    
    BOOL scucess = [parameters writeToFile:filePath atomically:YES];
    return scucess;
    
}

/*
 *目标：对已经存在的数据进行追加
 *parameters 数组
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */
+ (BOOL)addToArray:(NSArray *)parameters saveToPath:(NSString *)filePath {
    if (!parameters || !filePath) {
        NSLog(@"存储文件路径或者数据为空");
        return NO;
    }
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSString *lastPathComponentDelete = [filePath stringByDeletingLastPathComponent];
    NSLog(@"value is %@",lastPathComponentDelete);
    if (![fileM fileExistsAtPath:lastPathComponentDelete]) {
        NSError *createError = nil;
        if (![fileM createDirectoryAtPath:lastPathComponentDelete withIntermediateDirectories:YES attributes:nil error:&createError]) {
            NSLog(@"创建目标路径失败 %@",createError.description);
            return NO;
        };
    }
    
    NSArray *sourceArr = [QLFileSaveManager getArrayAtPath:filePath];
   
    NSMutableArray *parameterArr = nil;
    
    if (sourceArr) {
         parameterArr = [NSMutableArray arrayWithArray:sourceArr];
        [parameterArr addObjectsFromArray:parameterArr];
    }else {
         parameterArr = [NSMutableArray arrayWithArray:parameters];
    }
    
    BOOL scucess = [parameters writeToFile:filePath atomically:YES];
    return scucess;
    
}
/*
 *parameters ，字典
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */
+ (BOOL)saveDictionary:(NSDictionary *)parameters saveToPath:(NSString *)filePath {
    if (!parameters || !filePath) {
        NSLog(@"存储文件路径或者数据为空");
        return NO;
    }
    
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSString *lastPathComponentDelete = [filePath stringByDeletingLastPathComponent];
    if (![fileM fileExistsAtPath:lastPathComponentDelete]) {
        NSError *createError = nil;
        if (![fileM createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&createError]) {
            NSLog(@"创建目标路径失败 %@",createError.description);
            return NO;
        };
    }
    
    BOOL scucess = [parameters writeToFile:filePath atomically:YES];
    return scucess;
}

/*
 *parameters NSData
 *filePath  储存数据文件路径
 *返回值yes表示存储成功，NO表示失败
 */
+ (BOOL)saveData:(NSData *)parameters saveToPath:(NSString *)filePath {
    if (!parameters || !filePath) {
        NSLog(@"存储文件路径或者数据为空");
        return NO;
    }
    
    NSFileManager *fileM = [NSFileManager defaultManager];
    NSString *lastPathComponentDelete = [filePath stringByDeletingLastPathComponent];
    if (![fileM fileExistsAtPath:lastPathComponentDelete]) {
        NSError *createError = nil;
        if (![fileM createDirectoryAtPath:filePath withIntermediateDirectories:YES attributes:nil error:&createError]) {
            NSLog(@"创建目标路径失败 %@",createError.description);
            return NO;
        };
    }
    
    BOOL scucess = [parameters writeToFile:filePath atomically:YES];
    
    return scucess;
}

/*
 *获取数组
 *filePath 文件路径
 */
+ (NSArray *)getArrayAtPath:(NSString *)filePath {
    NSFileManager *fileM = [NSFileManager defaultManager];
    if (![fileM fileExistsAtPath:filePath]) {
        NSLog(@"目标文件不存在");
        return nil;
    }else {
        NSArray *array = [NSArray arrayWithContentsOfFile:filePath];
        return array;
    }
}

/*
 *获取字典
 *filePath 文件路径
 */
+ (NSDictionary *)getDictionaryAtPath:(NSString *)filePath {
    NSFileManager *fileM = [NSFileManager defaultManager];
    if (![fileM fileExistsAtPath:filePath]) {
        NSLog(@"目标文件不存在");
        return nil;
    }else {
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:filePath];
        return dictionary;
    }
    
}

/*
 *获取Data
 *filePath 文件路径
 */
+ (NSData *)getDataAtPath:(NSString *)filePath {
    NSFileManager *fileM = [NSFileManager defaultManager];
    if (![fileM fileExistsAtPath:filePath]) {
        NSLog(@"目标文件不存在");
        return nil;
    }else {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        return data;
    }
    
}

/*
 *删除文件
 */
+ (BOOL)removeFileOfPath:(NSString *)filePath {
    NSFileManager *fileM = [NSFileManager defaultManager];
    if ([fileM fileExistsAtPath:filePath]) {
        NSError *removeEerror = nil;
       BOOL success = [fileM removeItemAtPath:filePath error:&removeEerror];
        if (!success) {
            NSLog(@"remove file failed because %@",removeEerror.description);
        }
        return success;
    }else {
        return YES;
    }
}

/*
 *沙盒document路径
 */
+ (NSString *)pathForDocument {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [paths objectAtIndex:0];
    return docDir;
}
/*
 *沙盒cach路径
 */
+ (NSString *)pathForCach {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDir = [paths objectAtIndex:0];
    return cachesDir;
}

@end
