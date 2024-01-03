//
//  SLFileTransferFileModel.h
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import <Foundation/Foundation.h>
#import "FileTransfer.h"
#import "SLFileIOModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef enum : NSUInteger {
    SLTransferGlobleEventCheck,
    SLTransferGlobleEventCancel
} SLTransferGlobleEvent;

typedef void(^ProgressCallback)(float,float,float);
typedef void(^StatusCallback)(TaskState,SLTransferGlobleEvent);

@interface SLFileTransferFileModel : NSObject

@property (nonatomic, strong) NSString  *innerPath;
@property (nonatomic, strong) NSString  *taskId;
@property (nonatomic, strong) NSString  *fileId;
@property (nonatomic, copy) ProgressCallback  progressCallback;
@property (nonatomic, assign) TaskState taskState;
@property (nonatomic, copy) StatusCallback  statusCallback;
@property (nonatomic, assign) CGFloat  totolSize;
@property (nonatomic, strong) SLFileIOModel *ioModel;

- (instancetype)initWithInnerPath:(NSString *)innerPath taskId:(NSString *)taskId ioModel:(SLFileIOModel *)ioModel;

@end

NS_ASSUME_NONNULL_END
