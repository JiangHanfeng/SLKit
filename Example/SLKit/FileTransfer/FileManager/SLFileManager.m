//
//  SLFileManager.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import "SLFileManager.h"


@interface  SLFileManager()

@property (nonatomic,strong) NSFileManager *fileManager;

@end

@implementation SLFileManager

- (BOOL)createFolderWithPath:(NSString *)path {
    if (![self.fileManager fileExistsAtPath:path]) {
        [self.fileManager createDirectoryAtPath:path withIntermediateDirectories:NO attributes:nil error:nil];
        return  YES;
    }
    return  NO;
}

- (BOOL)createFileWithPath:(NSString *)path data:(nullable NSData *)data {
    if (![self.fileManager fileExistsAtPath:path]) {
        [self.fileManager createFileAtPath:path contents:data attributes:nil];
        return  YES;
    }
    return NO;
}

- (BOOL)fileExistsAtPath:(NSString *)path {
    return [self.fileManager fileExistsAtPath:path];
}

- (BOOL)deleteFileWithPath:(NSString *)path {
    if ([self.fileManager fileExistsAtPath:path]) {
        return  [self.fileManager removeItemAtPath:path error:nil];
    }
    return NO;
}

- (BOOL)copyFileWithPath:(NSString *)path toPath:(NSString *)toPath {
    if (![self.fileManager fileExistsAtPath:path]) {
        return NO;
    }
    return [self.fileManager copyItemAtPath:path toPath:toPath error:nil];
}

#pragma mark - get

- (NSFileManager *)fileManager {
    if(_fileManager == nil){
        _fileManager = [[NSFileManager alloc] init];
    }
    return _fileManager;
}

@end
