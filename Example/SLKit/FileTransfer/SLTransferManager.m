//
//  SLTransferManager.m
//  SLKit_Example
//
//  Created by shenjianfei on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import "SLTransferManager.h"
#import "SLFileTransferManager.h"
#import "SLWaitSendFileModel.h"
#import "SLLocalFileManger.h"
#import "SLFileManager.h"
#import "SLHeader.h"

static SLTransferManager *singleton = nil;

@interface SLTransferManager()
@property (nonatomic,strong) SLFileTransferManager *fileTransferManager;

//同时只能发送一个
@property (nonatomic,strong) NSMutableArray<SLWaitSendFileModel *> *sendIOModels;
@property (nonatomic,strong,nullable) SLFileIOModel *currentSendIOModel;

//同时可以接收多个
@property (nonatomic,strong) NSMutableArray<SLFileIOModel *> *receiveIOModels;

@property (nonatomic,strong) SLLocalFileManger *localFileListManger;
@property (nonatomic,strong) SLFileManager *fileManager;



@property (nonatomic,copy) NSString *deviceId;
@property (nonatomic,copy) NSString *deviceName;


@property (nonatomic,copy) NSString *sendIp;
@property (nonatomic,assign) int sendControlPort;
@property (nonatomic,assign) int sendDataPort;
@property (nonatomic,copy) NSString *sendDeviceId;

@end

@implementation SLTransferManager

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[SLTransferManager alloc] init];
    });
    return singleton;
}

- (void)configWithDeviceId:(NSString *)deviceId deviceName:(NSString *)deviceName {
    self.deviceId = deviceId;
    self.deviceName = deviceName;
    [self.fileTransferManager activateWithDeviceId:self.deviceId deviceName:self.deviceName bufferSize:1024*1024*2 outTime:6];;
    @weakify(self);
    self.fileTransferManager.receiveFileRequestBlock = ^(NSString * _Nonnull taskId, NSString * _Nonnull mac, NSString * _Nonnull deviceName, NSArray<SLFileModel *> * _Nonnull files) {
        @strongify(self);
        if(self.receiveFileRequestBlock){
            self.receiveFileRequestBlock(self.sendDeviceId,taskId,files);
        }
    };
    self.fileTransferManager.receivingFileUpdateStatusBlock = ^(NSString * _Nonnull taskId, SLFileIOModelStatusType statusType) {
        @strongify(self);
        if(self.cancelReceiveFileBlock){
            self.cancelReceiveFileBlock(self.sendDeviceId, taskId, statusType == CancelInitiativeTransfer);
        }
    };
}

- (void)configSendInfoWithDeviceId:(NSString *)deviceId Ip:(NSString *)ip controlPort:(int)controlPort dataPort:(int)dataPort {
    self.sendDeviceId = deviceId;
    self.sendIp = ip;
    self.sendControlPort = controlPort;
    self.sendDataPort = dataPort;
}

- (int)controlPort {
    return self.fileTransferManager.controlPort;
}

- (int)dataPort {
    return self.fileTransferManager.dataPort;
}

//当前接收的任务(多任务)
- (NSArray<SLFileTransferModel *> *)currentReceiveFileTransfer {
    NSMutableArray<SLFileTransferModel *> *models = [NSMutableArray array];
    NSArray<SLFileIOModel *> *ioModels = self.receiveIOModels;
    [ioModels enumerateObjectsUsingBlock:^(SLFileIOModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        SLFileTransferModel *model = [obj toFileTransferModel];
        if(model){
            [models addObject:model];
        }
    }];
    return  models;
}

////当前发送的任务(单任务)
- (nullable SLFileTransferModel *)currentSendFileTransfer {
    SLFileIOModel *model = self.currentSendIOModel;
    if(model){
        return [model toFileTransferModel];
    }
    return nil;
}

//接收的文件
- (NSArray<SLFileModel *> *)receiveFiles {
    return [self.localFileListManger queryReceiveData];
}

- (void)deleteReceiveFiles:(NSArray<SLFileModel *> *)files {
    @weakify(self);
    [files enumerateObjectsUsingBlock:^(SLFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        [self.fileManager deleteFileWithPath:[NSString stringWithFormat:@"%@%@",[self filesPath],[obj fullPath]]];
        [self.localFileListManger deleteDataWithPath:obj.path name:obj.name extensionName:obj.extensionName isSend:NO];
    }];
}

- (NSArray<SLFileModel *> *)sendFiles {
    return [self.localFileListManger querySendData];
}

- (void)deleteSendFiles:(NSArray<SLFileModel *> *)files {
    @weakify(self);
    [files enumerateObjectsUsingBlock:^(SLFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @strongify(self);
        [self.localFileListManger deleteDataWithPath:obj.path name:obj.name extensionName:obj.extensionName isSend:YES];
    }];
}

- (void)startSendFile {
    [self.fileManager deleteFileWithPath:[self tmpFilesPath]];
}

- (nullable SLFileModel *)createSendFileModelWithVideo:(NSString *)videoName data:(NSData *)data {
    if (videoName == nil || videoName.length == 0 || data == nil || data.length == 0) {
        return nil;
    }
    NSArray<NSString *> *list = [videoName componentsSeparatedByString:@"."];
    if(list.count != 2) {
        return nil;
    }
    SLFileModel *model = [[SLFileModel alloc] init];
    model.name = list[0];
    model.extensionName = list[1];
    [self.fileManager createFileWithPath:[NSString stringWithFormat:@"%@%@",[self tmpFilesPath],[model fullPath]] data:data];
    return  model;
}

- (nullable SLFileModel *)createSendFileModelWithImage:(UIImage *)image {
    if (image == nil) {
        return nil;
    }
    NSData *data = nil;
    NSString *typeStr = [self imagetypeWithImage:image];
    if ([typeStr isEqualToString:@"png"]) {
        data = UIImagePNGRepresentation(image);
    } else if ([typeStr isEqualToString:@"jpeg"]) {
        data = UIImageJPEGRepresentation(image, 1);
    }
    if(data == nil){
        return nil;
    }

    SLFileModel *model = [[SLFileModel alloc] init];
    model.name = [self temFileName];
    model.extensionName = typeStr;

    [self.fileManager createFileWithPath:[NSString stringWithFormat:@"%@%@",[self tmpFilesPath],[model fullPath]] data:data];
    return  model;
}

- (nullable SLFileModel *)createSendFileModelWithPath:(NSString *)path {
    
    NSArray<NSString *> *pathLists = [path componentsSeparatedByString:@"/"];
    if (pathLists.count == 0) {
        return nil;
    }
    
    NSArray<NSString *> *infoList = [pathLists.lastObject componentsSeparatedByString:@"."];
    if (infoList.count != 2) {
        return nil;
    }
    
    SLFileModel *model =  [[SLFileModel alloc] init];
    model.name = infoList[0];
    model.extensionName = infoList[1];
    
    [self.fileManager copyFileWithPath:path
                                toPath:[NSString stringWithFormat:@"%@%@",[self tmpFilesPath],[model fullPath]]];
    return model;
}

- (void)prepareSendFileModelWithModel:(SLFileModel *)model {
    [self.fileManager copyFileWithPath:[NSString stringWithFormat:@"%@%@",[self filesPath],[model fullPath]]
                                toPath:[NSString stringWithFormat:@"%@%@",[self tmpFilesPath],[model fullPath]]];
}

//发送文件
- (BOOL)sendFiles:(NSArray<SLFileModel *> *)files startBlock:(void(^)(NSString *,NSArray<SLFileModel *> *))block {
    SLWaitSendFileModel *model = [[SLWaitSendFileModel alloc] init];
    model.files = files;
    model.startSendFileBlock = block;
    [self.sendIOModels addObject:model];
    
    [self sendFileWithCompleteBlock:^{}];
    return YES;
}

- (void)respondReceiveFilesWithTaskId:(NSString *)taskId files:(NSArray<SLFileModel *> *)files accept:(BOOL)accept{
    SLFileIOModel *model = [self createFileIoModelWithIp:nil taskId:taskId files:files type:receiveFile];
    [self.receiveIOModels addObject:model];
    if(accept){
        [self receiveFileTransferStatusWithModel:self.sendDeviceId taskId:model.taskId status:FileTransmitting];
    }
    [[SLFileTransferManager shareManager] receiveFileWithIoModel:model savepath:[self filesPath] accept:accept];
}

//取消任务
- (void)cancelFilesWithTaskId:(nullable NSString *)taskId {
    if(!taskId){
        return;
    }
    @weakify(self);
    if(self.currentSendIOModel && [taskId isEqualToString:self.currentSendIOModel.taskId]) {
        [[SLFileTransferManager shareManager] cancelDeleteUnfinishedFileWithTaskId:taskId];
        [[SLFileTransferManager shareManager] removeTaskWithId:taskId];
        
        [self sendFileTransferStatusWithModel:self.sendDeviceId taskId:taskId status:CancelInitiativeTransfer];
        
        self.currentSendIOModel = nil;
        @weakify(self);
        [self sendFileWithCompleteBlock:^{
            @strongify(self);
            if(self.nonSendFileBlock){
                self.nonSendFileBlock(self.sendDeviceId);
            }
        }];
    } else {
        [self.receiveIOModels enumerateObjectsUsingBlock:^(SLFileIOModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            @strongify(self);
            if([obj.taskId isEqualToString:taskId]){
                [[SLFileTransferManager shareManager] cancelDeleteUnfinishedFileWithTaskId:taskId];
                [[SLFileTransferManager shareManager] removeTaskWithId:taskId];
                [self.receiveIOModels removeObject:obj];
                [self receiveFileTransferStatusWithModel:self.sendDeviceId taskId:taskId status:CancelInitiativeTransfer];
                *stop = YES;
            }
        }];
        [self.receiveIOModels removeAllObjects];
        
        if(self.nonReceiveFileBlock){
            self.nonReceiveFileBlock(self.sendDeviceId);
        }
    }
}

//获取文件路径
- (NSString *)localFilePath:(SLFileModel *)file {
    return [NSString stringWithFormat:@"%@%@",[self filesPath],[file fullPath]];
}


#pragma mark - other

- (NSString *)temFileName {
    NSDate *date = [NSDate date];
    return [NSString stringWithFormat:@"%ld",(long)([date timeIntervalSince1970] * 1000)];
}

- (NSString *)filesPath {
    NSString *homeDir = NSHomeDirectory();
    NSString *docDir = [homeDir stringByAppendingPathComponent:@"Documents"];
    NSString *path = [NSString stringWithFormat:@"%@/SCLite",docDir];
    [self.fileManager createFolderWithPath:path];
    return path;
}

- (NSString *)tmpFilesPath {
    NSString *homeDir = NSHomeDirectory();
    NSString *docDir = [homeDir stringByAppendingPathComponent:@"Documents"];
    NSString *path = [NSString stringWithFormat:@"%@/tmpFilesPath",docDir];
    [self.fileManager createFolderWithPath:path];
    return path;
}

- (NSString *)dbPath {
    NSString *homeDir = NSHomeDirectory();
    NSString *docDir = [homeDir stringByAppendingPathComponent:@"Documents"];
    return docDir;
}

- (NSString *)imagetypeWithImage:(UIImage *)image {
    NSData *date =UIImagePNGRepresentation(image);
    if (date == nil) {
        return @"png";
    } else {
        return @"jpeg";
    }
}

- (void)sendFileWithCompleteBlock:(void(^)(void))block {
    if(self.currentSendIOModel){
        return;
    }
    if(self.sendIOModels.count > 0){
        SLWaitSendFileModel *model = self.sendIOModels[0];
        self.currentSendIOModel = [self createFileIoModelWithIp:self.sendIp taskId:nil files:model.files type:sendFile];
        if(model.startSendFileBlock){
            model.startSendFileBlock(self.currentSendIOModel.taskId,model.files);
        }
        model.startSendFileBlock = nil;
        if(self.currentSendIOModel.updateStatusBlock){
            self.currentSendIOModel.updateStatusBlock(FileTransmitting);
        }
        [self.sendIOModels removeObjectAtIndex:0];
    } else {
        if(block){
            block();
        }
    }
}

- (SLFileIOModel *)createFileIoModelWithIp:(nullable NSString *)ip
                                    taskId:(nullable NSString *)taskId
                                     files:(NSArray<SLFileModel *> *)files
                                      type:(SLFileIOModelType)type {
    __block NSString *rootPath = [self tmpFilesPath];
    SLFileIOModel *ioModel = nil;
    if (type == receiveFile) {
        ioModel =  [[SLFileIOModel alloc] initWithTaskId:taskId deviceId:self.sendDeviceId  files:files type:receiveFile];
    } else {
        ioModel = [[SLFileTransferManager shareManager] sendFileWithIp:ip controlPort:self.sendControlPort deviceId:self.sendDeviceId dataPort:self.sendDataPort rootPath:rootPath files:files];
    }
    __block SLFileIOModel *brIoModel = ioModel;
    @weakify(self);
    ioModel.updateStatusBlock = ^(SLFileIOModelStatusType status){
        @strongify(self);
        if (status == CompleteTransfer){
            if (ioModel.type == sendFile) {
                if(self.sendFileProgressBlock){
                    self.sendFileProgressBlock(brIoModel.deviceId,taskId,1.0);
                }
            } else {
                if(self.receiveFileProgressBlock){
                    self.receiveFileProgressBlock(brIoModel.deviceId,taskId,1.0);
                }
            }
        }
        
        if (ioModel.type == sendFile) {
            if(status == FileTransmitting){
                if(self.currentSendIOModel){
                   [self sendFileTransferStatusWithModel:brIoModel.deviceId taskId:brIoModel.taskId status:(int)status];
                }
                if(self.sendFileProgressBlock){
                    self.sendFileProgressBlock(brIoModel.deviceId,taskId,0.0);
                }
            } else {
                if(self.currentSendIOModel){
                    [self sendFileTransferStatusWithModel:brIoModel.deviceId taskId:brIoModel.taskId status:(int)status];
                }
            }
        } else {
            if(status == FileTransmitting){
                [self receiveFileTransferStatusWithModel:brIoModel.deviceId taskId:brIoModel.taskId status:(int)status];
                if(self.receiveFileProgressBlock){
                    self.receiveFileProgressBlock(brIoModel.deviceId,taskId,1.0);
                }
            } else {
                [self receiveFileTransferStatusWithModel:brIoModel.deviceId taskId:brIoModel.taskId status:(int)status];
            }
        }
        
        //移除任务
        if (status == RefuseTransfer || status == CompleteTransfer ||
            status == CancelPassivityTransfer || status == CancelInitiativeTransfer ||
            status == NoFileTransfer || status == RemoteInErrorTransfer ||
            status == ErrorTransfer) {
            
            if( status == NoFileTransfer || status == RemoteInErrorTransfer ||
               status == ErrorTransfer ) {
                [[SLFileTransferManager shareManager] cancelDeleteUnfinishedFileWithTaskId:brIoModel.taskId];
            }
            [[SLFileTransferManager shareManager] removeTaskWithId:brIoModel.taskId];
            
            if(ioModel.type == sendFile){
                self.currentSendIOModel = nil;
                @weakify(self);
                [self sendFileWithCompleteBlock:^{
                    @strongify(self);
                    if(self.nonSendFileBlock){
                        self.nonSendFileBlock(brIoModel.deviceId);
                    }
                }];
            } else {
                [self.receiveIOModels removeObject:brIoModel];
                if(self.receiveIOModels.count == 0){
                    if(self.nonReceiveFileBlock){
                        self.nonReceiveFileBlock(brIoModel.deviceId);
                    }
                }
            }
        }
    };
    
    ioModel.updateProgressBlock = ^(float pro, float rate, float length) {
        @strongify(self);
        if (ioModel.type == sendFile) {
            if(self.sendFileProgressBlock){
                self.sendFileProgressBlock(brIoModel.deviceId,taskId,pro);
            }
        } else {
            if(self.receiveFileProgressBlock){
                self.receiveFileProgressBlock(brIoModel.deviceId,taskId,pro);
            }
        }
    };
    
    ioModel.completeSendFileBlock = ^(SLFileModel * _Nonnull file) {
        @strongify(self);
        if (brIoModel.type == sendFile) {
            UInt64 time = (UInt64)[[NSDate date] timeIntervalSince1970];
            [self.localFileListManger insertDataWithPath:file.path name:file.name extensionName:file.extensionName time:time isSend:YES];
            if(self.sendFileCompleteBlock){
                self.sendFileCompleteBlock(brIoModel.deviceId,taskId,file,(long long)brIoModel.transferLength);
            }
        } else {
            UInt64 time = (UInt64)[[NSDate date] timeIntervalSince1970];
            [self.localFileListManger insertDataWithPath:file.path name:file.name extensionName:file.extensionName time:time isSend:NO];
            if(self.receiveFileCompleteBlock){
                self.receiveFileCompleteBlock(brIoModel.deviceId,taskId,file,(long long)brIoModel.transferLength);
            }
        }
    };
    return ioModel;
}

- (void)sendFileTransferStatusWithModel:(NSString *)model taskId:(NSString *)taskId status:(int)status {
    
    if(status == FileTransmitting){
        if(self.startSendFileBlock){
            self.startSendFileBlock(model,taskId);
        }
    } else if(status == CompleteTransfer){
        if(self.completeSendFileBlock){
            self.completeSendFileBlock(model,taskId);
        }
    } else if(status == RefuseTransfer){
        if(self.refuseSendFileBlock){
            self.refuseSendFileBlock(model,taskId);
        }
    }  else if (status == CancelPassivityTransfer || status == CancelInitiativeTransfer){
        if(self.cancelSendFileBlock){
            self.cancelSendFileBlock(model,taskId,status == CancelInitiativeTransfer);
        }
    } else if (status == OversizedTransfer || status == NoFileTransfer || status == RemoteInErrorTransfer || status == ErrorTransfer ) {
        NSLog(@"发送文件错误：%d",status);
        if (status == OversizedTransfer){
            if(self.sendFileFailBlock){
                self.sendFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        } else if (status == NoFileTransfer){
            if(self.sendFileFailBlock){
                self.sendFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        } else if (status == RemoteInErrorTransfer){
            if(self.sendFileFailBlock){
                self.sendFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        } else if (status == ErrorTransfer){
            if(self.sendFileFailBlock){
                self.sendFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        }
    }
}

- (void)receiveFileTransferStatusWithModel:(NSString *)model taskId:(NSString *)taskId status:(int)status {
    if(status == FileTransmitting){
        if(self.startReceiveFileBlock){
            self.startReceiveFileBlock(model,taskId);
        }
    } else if(status == CompleteTransfer) {
        if(self.completeReceiveFileBlock){
            self.completeReceiveFileBlock(model,taskId);
        }
    } else if (status == CancelPassivityTransfer || status == CancelInitiativeTransfer){
        if(self.cancelReceiveFileBlock){
            self.cancelReceiveFileBlock(model,taskId,status == CancelInitiativeTransfer);
        }
    } else if (status == OversizedTransfer || status == NoFileTransfer || status == RemoteInErrorTransfer || status == ErrorTransfer ) {
        NSLog(@"接收文件错误：%d",status);
        if (status == OversizedTransfer){
            if(self.receiveFileFailBlock){
                self.receiveFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        } else if (status == NoFileTransfer){
            if(self.receiveFileFailBlock){
                self.receiveFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        } else if (status == RemoteInErrorTransfer){
            if(self.receiveFileFailBlock){
                self.receiveFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        } else if (status == ErrorTransfer){
            if(self.receiveFileFailBlock){
                self.receiveFileFailBlock(model,taskId,[NSError errorWithDomain:NSCocoaErrorDomain code:status userInfo:nil]);
            }
        }
    }
}




#pragma mark - get

- (SLFileTransferManager *)fileTransferManager {
    if(!_fileTransferManager){
        _fileTransferManager = [SLFileTransferManager shareManager];
    }
    return _fileTransferManager;
}

- (NSMutableArray<SLFileIOModel *> *)receiveIOModels {
    if(!_receiveIOModels){
        _receiveIOModels = [NSMutableArray array];
    }
    return _receiveIOModels;
}


- (SLLocalFileManger *)localFileListManger {
    if(!_localFileListManger){
        _localFileListManger = [[SLLocalFileManger alloc] init];
    }
    return _localFileListManger;
}


- (SLFileManager *)fileManager {
    if (_fileManager == nil) {
        _fileManager = [[SLFileManager alloc] init];
    }
    return _fileManager;
}

- (NSMutableArray<SLWaitSendFileModel *> *)sendIOModels {
    if(!_sendIOModels){
        _sendIOModels = [NSMutableArray array];
    }
    return _sendIOModels;
}




@end
