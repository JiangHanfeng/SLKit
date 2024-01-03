//
//  SLFileTransferManager.m
//  FileTransfer
//
//  Created by shenjianfei on 2023/6/6.
//

#import "SLFileTransferManager.h"
#import "FileTransfer.h"
#import "NSString+Transition.h"
#import "SLFileTransferFileModel.h"
#import "SLKit_Example-Swift.h"

static SLFileTransferManager *singleton = nil;

@interface SLFileTransferManager()
@property (nonatomic,strong)   NSMutableArray<SLFileTransferFileModel *>  *sendFiles;
@property (nonatomic,strong)   NSMutableArray<SLFileTransferFileModel *>  *receiveFiles;


@property (nonatomic,assign,readwrite) int controlPort;
@property (nonatomic,assign,readwrite) int dataPort;

@property (nonatomic,assign) BOOL isConfig;
@end

@implementation SLFileTransferManager

FileTransfer ft;

+ (instancetype)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[SLFileTransferManager alloc] init];
    });
    return singleton;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.controlPort = 30000+arc4random()%1000;
        self.dataPort = self.controlPort+1;
        self.isConfig = NO;
    }
    return self;
}

- (void)activateWithDeviceId:(NSString *)deviceId
                   deviceName:(NSString *)deviceName
                    bufferSize:(int)buferSize
                      outTime:(int)outTime {
    if(self.isConfig) {
        ft.UnInit();
    }
    ft.Init(self.controlPort,
            self.dataPort,
            [deviceId toWString],
            buferSize,
            [deviceName toWString],
            2,
            outTime);
    ft.transferRequestEvent = receivingFiles;
    ft.progressChangeEvent = fileProgressChanged;
    ft.taskStateChangeEvent = fileStatusChanged;
    ft.loger = LogEventCallback;
    NSLog(@"文件传输初始化");
    self.isConfig = YES;
}

- (void)deactivation {
    if (self.isConfig) {
        ft.UnInit();
        self.isConfig = NO;
    }
}

- (SLFileIOModel *)sendFileWithIp:(NSString *)ip controlPort:(int)controlPort dataPort:(int)dataPort rootPath:(NSString *)path device:(SLFreeStyleDevice *)device files:(NSArray<SLFileModel *> *)files{
    
    if(controlPort == 0 || dataPort == 0){
        NSLog(@"文件传输端口为空");
    }
    
    std::wstring taskId = std::wstring();
    std::list<std::wstring> fileLists = std::list<std::wstring>();
    for (SLFileModel *file in files) {
        NSString *filePath = [NSString stringWithFormat:@"%@%@",path,[file fullPath]];
        fileLists.push_front([filePath toWString]);
    }
    ft.RequestFileTransfer([ip toWString],controlPort,dataPort,0, fileLists, taskId);
    NSString *taskIdStr = [NSString stringWithWString:taskId];
    SLFileIOModel *ioModel =  [[SLFileIOModel alloc] initWithTaskId:taskIdStr device:device files:files type:sendFile];
    SLFileTransferFileModel *fileModel =  [[SLFileTransferFileModel alloc] initWithInnerPath:path
                                                                                      taskId:taskIdStr
                                                                                      ioModel:ioModel];
    [self.sendFiles addObject:fileModel];
    return ioModel;
}

- (void)receiveFileWithIoModel:(SLFileIOModel *)model savepath:(NSString *)savepath accept:(BOOL)accept {
    model.type = receiveFile;
    SLFileTransferFileModel *fileModel =  [[SLFileTransferFileModel alloc] initWithInnerPath:savepath
                                                                                      taskId:model.taskId
                                                                                      ioModel:model];
    fileModel.innerPath = savepath;
    [self.receiveFiles addObject:fileModel];
    if (accept){
        ft.FileTransferResponse([model.taskId toWString],confirming,[savepath toWString], 0);
    } else {
        ft.FileTransferResponse([model.taskId toWString],reject,[savepath toWString], 0);
    }
}

- (void)cancelDeleteAllFileWithTaskId:(NSString *)taskId {
    ft.CancelFileTransfer([taskId toWString],[@"" toWString],DeleteTaskFile);
    [self removeTaskWithId:taskId];
}

- (void)cancelDeleteUnfinishedFileWithTaskId:(NSString *)taskId {
    ft.CancelFileTransfer([taskId toWString],[@"" toWString],DeleteUnfinished);
    [self removeTaskWithId:taskId];
}

- (void)cancelFileWithTaskId:(NSString *)taskId {
    ft.CancelFileTransfer([taskId toWString],[@"" toWString],DoNothing);
    [self removeTaskWithId:taskId];
}

- (void)removeTaskWithId:(NSString *)taskId {
    [self.receiveFiles enumerateObjectsUsingBlock:^(SLFileTransferFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.taskId == taskId){
            [self.receiveFiles removeObject:obj];
            *stop = YES;
        }
    }];
    
    [self.sendFiles enumerateObjectsUsingBlock:^(SLFileTransferFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.taskId == taskId){
            [self.sendFiles removeObject:obj];
            *stop = YES;
        }
    }];
}

- (NSArray<SLFileIOModel *> *)currentFileIOModels {
    __block NSMutableArray<SLFileIOModel *> *array = [NSMutableArray array];
    [self.sendFiles enumerateObjectsUsingBlock:^(SLFileTransferFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:obj.ioModel];
    }];
    [self.receiveFiles enumerateObjectsUsingBlock:^(SLFileTransferFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [array addObject:obj.ioModel];
    }];
    return array;
}

- (nullable SLFileIOModel *)fileIOModelWithTaskId:(NSString *)taskId {
    for (SLFileTransferFileModel *obj in self.sendFiles) {
        if (obj.taskId == taskId){
            return obj.ioModel;
        }
    }
    for (SLFileTransferFileModel *obj in self.receiveFiles) {
        if (obj.taskId == taskId){
            return obj.ioModel;
        }
    }
    return nil;
}

#pragma mark -- 接收回件通知
int receivingFiles(FileTransferRequestInfo info) {
    NSLog(@"接收回件通知");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray<SLFileModel *> *models = [NSMutableArray array];
        std::list<TransferFileInfo> flist = info.fileList;
        std::list<TransferFileInfo>::iterator p1;
        for(p1=flist.begin();p1!=flist.end();p1++){
            SLFileModel *model = [[SLFileModel alloc] init];
            model.name = [NSString stringWithWString:p1->name];
            model.extensionName = [[NSString stringWithWString:p1->extensionName] substringFromIndex:1];
            [models addObject:model];
        }
        if(singleton.receiveFileRequestBlock) {
            singleton.receiveFileRequestBlock([NSString stringWithWString:info.taskId],
                                              [NSString stringWithWString:info.senderDeviceId],
                                              [NSString stringWithWString:info.senderDeviceName],
                                              models);
        }
    });
    return 0;
}

#pragma mark -- 文件进度回调
int fileProgressChanged(FileTransferProgress progress) {
    NSLog(@"文件进度回调");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSMutableArray *container = singleton.receiveFiles;
        if(progress.type == 0){//文件发送
            container = singleton.sendFiles;
        }
        __block SLFileTransferFileModel *file = nil;
        [container enumerateObjectsUsingBlock:^(SLFileTransferFileModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *str0 = obj.taskId;
            NSString *str1 = [NSString stringWithWString:progress.taskId];
            if ([str0 isEqualToString:str1]) {
                file = obj;
                *stop = YES;
            }
        }];
        
        if(file != nil){
            file.ioModel.currentProgress = progress.progress/100.0;
            file.ioModel.transferLength = progress.transferLength;
            if(file.ioModel.updateProgressBlock){
                file.ioModel.updateProgressBlock(file.ioModel.currentProgress,progress.transferRate,file.ioModel.transferLength);
            }
        }
    });
    return 0;
}

#pragma mark -- 文件状态改变
int fileStatusChanged(FileTransferState state) {
    NSLog(@"文件状态改变");
    dispatch_async(dispatch_get_main_queue(), ^{
        if(state.type == 1){
            __block BOOL exist = NO;
            NSString *str1 = [NSString stringWithWString:state.taskId];
            [singleton.receiveFiles enumerateObjectsUsingBlock:^(SLFileTransferFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if([str1 isEqualToString:obj.taskId]){
                    exist = YES;
                }
            }];
            if(!exist){
                if(singleton.receivingFileUpdateStatusBlock){
                    singleton.receivingFileUpdateStatusBlock(str1,(SLFileIOModelStatusType)state.stat);
                }
                return;
            }
        }
        
        NSMutableArray *container = singleton.receiveFiles;
        if(state.type == 0){ //发送任务
            container = singleton.sendFiles;
        }
        
        __block SLFileTransferFileModel *file = nil;
        [container enumerateObjectsUsingBlock:^(SLFileTransferFileModel *obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSString *str0 = obj.taskId;
            NSString *str1 = [NSString stringWithWString:state.taskId];
            if ([str0 isEqualToString:str1]) {
                file = obj;
                *stop = YES;
            }
        }];
        
        if (file != nil){
            file.taskState = state.stat;
            file.ioModel.status = (SLFileIOModelStatusType)state.stat;
            
            FileTransferTask taskinfo;
            ft.GetTask(state.taskId,taskinfo);
            long sizet = 0;
            std::list<TransferFileInfo> flist = taskinfo.requestInfo.fileList;
            std::list<TransferFileInfo>::iterator p1;
            for(p1=flist.begin();p1!=flist.end();p1++){
                sizet+=(p1->size);
                if (p1->stat == f_TransferDone || file.ioModel.status == CompleteTransfer) {
                    NSString *name = [NSString stringWithWString:p1->name];
                    NSString *exname = [[NSString stringWithWString:p1->extensionName] substringFromIndex:1];
                    [file.ioModel.fileModels enumerateObjectsUsingBlock:^(SLFileModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([obj.name isEqualToString:name] && [obj.extensionName isEqualToString:exname]) {
                            if(file.ioModel.completeSendFileBlock){
                                file.ioModel.completeSendFileBlock(obj);
                            }
                            *stop = YES;
                        }
                    }];
                }
            }
            if (file.taskState == CheckLocalFileInfo) {
                file.totolSize = sizet;
            }
            if(file.ioModel.updateStatusBlock){
                file.ioModel.updateStatusBlock(file.ioModel.status);
            }
        }
    });
    return 0;
}

#pragma mark -- Log
void LogEventCallback(logLevel level,const wchar_t* msg)
{
    NSLog(@"SDK log:[%@]%@\n",[NSString stringWithWString:GetEnumString(level)],[NSString stringWithWString:msg]);
}

#pragma mark - lazy load

- (NSMutableArray<SLFileTransferFileModel *> *)receiveFiles {
    if (!_receiveFiles) {
        _receiveFiles = [NSMutableArray array];
    }
    return _receiveFiles;
}

- (NSMutableArray<SLFileTransferFileModel *> *)sendFiles {
    if (!_sendFiles) {
        _sendFiles = [NSMutableArray array];
    }
    return _sendFiles;
}


@end
