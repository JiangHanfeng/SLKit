//
//  SLFileTransferModel.h
//  OMNIEnjoySDK
//
//  Created by shenjianfei on 2023/11/20.
//

#import <Foundation/Foundation.h>
#import "SLFileModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,SLFileTransferType) {
    sendFileTransfer = 0,
    receiveFileTransfer = 1
};

@interface SLFileTransferModel : NSObject

@property (nonatomic,copy) NSString *taskId;
@property (nonatomic,copy) NSArray<SLFileModel *> *files;
@property (nonatomic,assign) float currentProgress;
@property (nonatomic,assign) SLFileTransferType type;

@end

NS_ASSUME_NONNULL_END
