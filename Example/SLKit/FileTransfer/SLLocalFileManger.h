//
//  SLLocalFileManger.h
//  Test-OC
//
//  Created by shenjianfei on 2023/6/13.
//

#import <Foundation/Foundation.h>
#import "SLFileModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLLocalFileManger : NSObject
- (NSArray<SLFileModel *> *)querySendData;
- (NSArray<SLFileModel *> *)queryReceiveData;
- (BOOL)insertDataWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName time:(UInt64)time isSend:(BOOL)isSend;
- (BOOL)deleteDataWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName isSend:(BOOL)isSend;
@end

NS_ASSUME_NONNULL_END
