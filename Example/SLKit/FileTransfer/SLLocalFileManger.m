//
//  SLLocalFileManger.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/13.
//

#import "SLLocalFileManger.h"
#import "SLLocalFileDBModel.h"

@interface SLLocalFileManger ()
@end

@implementation SLLocalFileManger

- (BOOL)insertDataWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName time:(UInt64)time isSend:(BOOL)isSend {
    if ([self queryFileWithPath:path name:name extensionName:extensionName isSend:isSend] != nil){
        [self deleteDataWithPath:path name:name extensionName:extensionName isSend:isSend];
    }
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
        [realm addObject: [SLLocalFileDBModel modelWithPath:path name:name extensionName:extensionName time:time type:isSend ? dbSend : dbReceive]];
    }];
    return YES;
}

- (NSArray<SLFileModel *> *)querySendData {
    NSMutableArray<SLFileModel *> *array = [NSMutableArray array];
    RLMResults *results = [[SLLocalFileDBModel objectsWhere:[NSString stringWithFormat:@" type = %d",(int)dbSend]] sortedResultsUsingKeyPath:@"time" ascending:NO];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
       for (SLLocalFileDBModel *obj in results) {
           [array addObject:[obj toFile]];
       }
    }];
    return  array;
}

- (NSArray<SLFileModel *> *)queryReceiveData {
    NSMutableArray<SLFileModel *> *array = [NSMutableArray array];
    RLMResults *results = [[SLLocalFileDBModel objectsWhere:[NSString stringWithFormat:@" type = %d",(int)dbReceive]] sortedResultsUsingKeyPath:@"time" ascending:NO];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
       for (SLLocalFileDBModel *obj in results) {
           [array addObject:[obj toFile]];
       }
    }];
    return  array;
}

- (SLFileModel *)queryFileWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName isSend:(BOOL)isSend {
    NSMutableArray<SLFileModel *> *files = [NSMutableArray array];
    RLMResults *results = [SLLocalFileDBModel objectsWhere:[NSString stringWithFormat:@"path = '%@' and name = '%@' and extensionName = '%@' and type = %d",path,name,extensionName,(int)(isSend ? dbSend : dbReceive)]];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
       for (SLLocalFileDBModel *obj in results) {
           [files addObject:[obj toFile]];
       }
    }];
    return files.count == 0 ? nil : files[0];
}

- (BOOL)deleteDataWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName isSend:(BOOL)isSend {
    int type = isSend ? dbSend : dbReceive;
    RLMResults *results = [SLLocalFileDBModel allObjects];
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm transactionWithBlock:^{
       for (SLLocalFileDBModel *obj in results) {
           if ([obj.path isEqualToString:path] && [obj.name isEqualToString:name] &&
               [obj.extensionName isEqualToString:extensionName] && obj.type == type){
               [realm deleteObject:obj];
           }
       }
    }];
    return YES;
}

@end
