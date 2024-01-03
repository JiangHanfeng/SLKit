//
//  SLFileTransferFileModel.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import "SLFileTransferFileModel.h"

@implementation SLFileTransferFileModel

- (instancetype)initWithInnerPath:(NSString *)innerPath taskId:(NSString *)taskId ioModel:(SLFileIOModel *)ioModel
{
    self = [super init];
    if (self) {
        self.innerPath = innerPath;
        self.taskId = taskId;
        self.ioModel = ioModel;
    }
    return self;
}

@end
