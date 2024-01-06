//
//  SLFileTransferManager.h
//  FileTransfer
//
//  Created by shenjianfei on 2023/6/6.
//

#import <Foundation/Foundation.h>
#import "SLFileIOModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLFileTransferManager : NSObject

@property (nonatomic,copy) void(^receiveFileRequestBlock)(NSString *taskId,NSString *mac,NSString *deviceName,NSArray<SLFileModel *> * files);
@property (nonatomic,copy) void(^receivingFileUpdateStatusBlock)(NSString *taskId,SLFileIOModelStatusType);


@property (nonatomic,assign,readonly) int controlPort;
@property (nonatomic,assign,readonly) int dataPort;

+ (instancetype)shareManager;

- (void)activateWithDeviceId:(NSString *)deviceId
                   deviceName:(NSString *)deviceName
                    bufferSize:(int)buferSize
                      outTime:(int)outTime;

- (void)deactivation;

- (SLFileIOModel *)sendFileWithIp:(NSString *)ip controlPort:(int)controlPort deviceId:(NSString *)deviceId dataPort:(int)dataPort rootPath:(NSString *)path files:(NSArray<SLFileModel *> *)files;

- (void)receiveFileWithIoModel:(SLFileIOModel *)model savepath:(NSString *)savepath accept:(BOOL)accept;

- (void)cancelDeleteAllFileWithTaskId:(NSString *)taskId;

- (void)cancelDeleteUnfinishedFileWithTaskId:(NSString *)taskId;

- (void)cancelFileWithTaskId:(NSString *)taskId;

- (NSArray<SLFileIOModel *> *)currentFileIOModels;

- (nullable SLFileIOModel *)fileIOModelWithTaskId:(NSString *)taskId;

- (void)removeTaskWithId:(NSString *)taskId;

@end

NS_ASSUME_NONNULL_END
