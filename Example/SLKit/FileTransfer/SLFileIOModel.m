//
//  SLFileIOModel.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import "SLFileIOModel.h"

@implementation SLFileIOModel

- (instancetype)initWithTaskId:(NSString *)taskId device:(SLFreeStyleDevice *)device files:(NSArray<SLFileModel *> *)files type:(SLFileIOModelType)type
{
    self = [super init];
    if (self) {
        self.taskId = taskId;
        self.deviceModel = device;
        self.fileModels = files;
        self.type = type;
    }
    return self;
}

@end
