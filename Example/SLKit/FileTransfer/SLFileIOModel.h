//
//  SLFileIOModel.h
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <WebKit/WKWebView.h>
#import <WebKit/WKNavigation.h>
#import <WebKit/WKUIDelegate.h>
#import <WebKit/WKScriptMessageHandler.h>
#import <CoreLocation/CLLocationManager.h>
//#import "SLKit_Example-Swift.h"
@class SLFileModel;
@class SLFreeStyleDevice;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,SLFileIOModelType) {
    sendFile = 0,//发送
    receiveFile = 1, //接收
};

typedef NS_ENUM(NSInteger,SLFileIOModelStatusType) {
    WaitTransfer = 0,//等待
    CheckTransferFile = 1,//检测传输文件
    ConfirmingTransfer,
    RefuseTransfer,//拒绝
    SuspendedTransfer,//暂停
    FileTransmitting,//传输中
    CancelPassivityTransfer,//被动取消
    CompleteTransfer, //完成
    CancelInitiativeTransfer,//主动取消
    OversizedTransfer,
    NoFileTransfer,//没有可以传输的文件
    RemoteInErrorTransfer,//对方进入阻断性错误导致任务终止
    ErrorTransfer = 99,//异常
};

@interface SLFileIOModel : NSObject

@property (nonatomic,strong) NSString *taskId;
@property (nonatomic,assign) SLFileIOModelStatusType status;
@property (nonatomic,assign) SLFileIOModelType type;
@property (nonatomic,copy) NSArray<SLFileModel *> *fileModels;
@property (nonatomic,strong) SLFreeStyleDevice *deviceModel;
@property (nonatomic,assign) float currentProgress;
@property (nonatomic,assign) float transferLength;

@property (nonatomic,copy) void(^updateStatusBlock)(SLFileIOModelStatusType);
@property (nonatomic,copy) void(^updateProgressBlock)(float,float,float);
@property (nonatomic,copy) void(^completeSendFileBlock)(SLFileModel *file);

- (instancetype)initWithTaskId:(NSString *)taskId device:(SLFreeStyleDevice *)device files:(NSArray<SLFileModel *> *)files type:(SLFileIOModelType)type;

@end

NS_ASSUME_NONNULL_END
