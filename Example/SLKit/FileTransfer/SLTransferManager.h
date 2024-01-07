//
//  SLTransferManager.h
//  SLKit_Example
//
//  Created by shenjianfei on 2024/1/6.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SLFileModel.h"
#import "SLFileTransferModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface SLTransferManager : NSObject

//接收文件
@property (nullable,nonatomic,copy) void(^receiveFileRequestBlock)(NSString *,NSString *,NSArray<SLFileModel *> *);
//开始接收文件
@property (nullable,nonatomic,copy) void(^startReceiveFileBlock)(NSString *,NSString *);
//接收进度条
@property (nullable,nonatomic,copy) void(^receiveFileProgressBlock)(NSString *,NSString *,float progress);
//取消接收
@property (nullable,nonatomic,copy) void(^cancelReceiveFileBlock)(NSString *,NSString *,BOOL);
//完成接收
@property (nullable,nonatomic,copy) void(^completeReceiveFileBlock)(NSString *,NSString *);
//接收失败
@property (nullable,nonatomic,copy) void(^receiveFileFailBlock)(NSString *,NSString *, NSError * _Nullable);
//没有接收文件
@property (nullable,nonatomic,copy) void(^nonReceiveFileBlock)(NSString *);
//接收某个文件完成
@property (nullable,nonatomic,copy) void(^receiveFileCompleteBlock)(NSString *,NSString *,SLFileModel *,long long);

//等待接收文件
@property (nullable,nonatomic,copy) void(^waitSendFileBlock)(NSString *,NSString *);
//开始发送文件
@property (nullable,nonatomic,copy) void(^startSendFileBlock)(NSString *,NSString *);
//发送进度条
@property (nullable,nonatomic,copy) void(^sendFileProgressBlock)(NSString *,NSString *,float progress);
//拒绝发送
@property (nullable,nonatomic,copy) void(^refuseSendFileBlock)(NSString *,NSString *);
//取消发送
@property (nullable,nonatomic,copy) void(^cancelSendFileBlock)(NSString *,NSString *,BOOL);
//完成发送
@property (nullable,nonatomic,copy) void(^completeSendFileBlock)(NSString *,NSString *);
//发送失败
@property (nullable,nonatomic,copy) void(^sendFileFailBlock)(NSString *,NSString *, NSError * _Nullable);
//没有可发生文件
@property (nullable,nonatomic,copy) void(^nonSendFileBlock)(NSString *);
//发送某个文件完成
@property (nullable,nonatomic,copy) void(^sendFileCompleteBlock)(NSString *,NSString *,SLFileModel *,long long);
//发送文件更新
@property (nullable,nonatomic,copy) void(^upDateSendFileBlock)(NSString *,NSString *);

@property (nonatomic,assign,readonly) int controlPort;
@property (nonatomic,assign,readonly) int dataPort;

+ (instancetype)shareManager;

- (void)configWithDeviceId:(NSString *)deviceId deviceName:(NSString *)deviceName;
//配置发送对象
- (void)configSendInfoWithDeviceId:(NSString *)deviceId Ip:(NSString *)ip controlPort:(int)controlPort dataPort:(int)dataPort;

//当前接收的任务(多任务)
- (NSArray<SLFileTransferModel *> *)currentReceiveFileTransfer;
////当前发送的任务(单任务)
- (nullable SLFileTransferModel *)currentSendFileTransfer;

//接收的文件
- (NSArray<SLFileModel *> *)receiveFiles;

- (void)deleteReceiveFiles:(NSArray<SLFileModel *> *)files;
//发送的文件
- (NSArray<SLFileModel *> *)sendFiles;

- (void)deleteSendFiles:(NSArray<SLFileModel *> *)files;

- (void)startSendFile;
//创建发送模型
- (nullable SLFileModel *)createSendFileModelWithImage:(UIImage *)image;
- (nullable SLFileModel *)createSendFileModelWithVideo:(NSString *)videoName data:(NSData *)data;;
- (nullable SLFileModel *)createSendFileModelWithPath:(NSString *)path;
//发送前准备
- (void)prepareSendFileModelWithModel:(SLFileModel *)model;
//发送文件(单个任务发送,开始发送调用block，并返回taskId)
- (BOOL)sendFiles:(NSArray<SLFileModel *> *)files startBlock:(void(^)(NSString *,NSArray<SLFileModel *> *))block;
//接收文件
- (void)respondReceiveFilesWithTaskId:(NSString *)taskId files:(NSArray<SLFileModel *> *)files accept:(BOOL)accept;
//取消任务
- (void)cancelFilesWithTaskId:(nullable NSString *)taskId;
//文件路径，用于显示
- (NSString *)localFilePath:(SLFileModel *)file;

- (NSString *)filesPath;

@end

NS_ASSUME_NONNULL_END
