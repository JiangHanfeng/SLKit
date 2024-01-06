//
//  SLFileIOModel.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import "SLFileIOModel.h"

@implementation SLFileIOModel

- (instancetype)initWithTaskId:(NSString *)taskId deviceId:(NSString *)deviceId files:(NSArray<SLFileModel *> *)files type:(SLFileIOModelType)type
{
    self = [super init];
    if (self) {
        self.taskId = taskId;
        self.fileModels = files;
        self.deviceId = deviceId;
        self.type = type;
    }
    return self;
}

- (nullable SLFileTransferModel *)toFileTransferModel {
    SLFileTransferModel *model = [[SLFileTransferModel alloc] init];
    model.taskId = self.taskId;
    model.files = [self.fileModels copy];
    model.currentProgress = self.currentProgress;
    model.type = self.type == sendFile ? sendFileTransfer : receiveFileTransfer;
    return model;
}

@end
