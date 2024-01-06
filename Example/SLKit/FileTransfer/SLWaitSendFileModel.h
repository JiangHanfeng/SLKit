//
//  SLWaitSendFileModel.h
//  OMNIEnjoySDK
//
//  Created by shenjianfei on 2023/11/6.
//

#import <Foundation/Foundation.h>
#import "SLFileIOModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLWaitSendFileModel : NSObject
@property (nonatomic,copy) NSArray<SLFileModel *> *files;
@property (nullable,nonatomic,copy) void(^startSendFileBlock)(NSString *,NSArray<SLFileModel *> *);
@end

NS_ASSUME_NONNULL_END
