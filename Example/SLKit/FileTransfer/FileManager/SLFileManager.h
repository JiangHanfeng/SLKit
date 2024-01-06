//
//  SLFileManager.h
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SLFileManager : NSObject

- (BOOL)createFolderWithPath:(NSString *)path;

- (BOOL)createFileWithPath:(NSString *)path data:(nullable NSData *)data;

- (BOOL)fileExistsAtPath:(NSString *)path;

- (BOOL)copyFileWithPath:(NSString *)path toPath:(NSString *)toPath;

- (BOOL)deleteFileWithPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
