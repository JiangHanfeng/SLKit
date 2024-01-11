#ifndef FileTransferReceiverTaskProcess_H
#define FileTransferReceiverTaskProcess_H
#include "FileTransferModel.h"
#include "string"
#include <thread>
#include <list>
#include "../Sockets/ClientHelper.h"
#include "JsonHelper.h"
#include "../Utils/tools.h"
#include "../Utils/MD5.h"
#include "../Utils/SimperSafeMap.h"
//#include "../Utils/ThreadsafeList.h"
#include "SubTask_Receive.h"
#include <mutex>
#include <map>
#include <future>
#define MaxHashCheckWaitTime 5//hash校验等待（指等待校验的时间）超时时间，单位秒
#define MaxHashCheckTime 300+MaxHashCheckWaitTime//hash校验（指计算过程用时）超时时间，单位秒，默认5分钟
#define AutoRetryDownloadTimeout 1*30 //自动重新下载启用时，进度更新的超时时间 单位秒 默认3分钟
class FileTransferReceiverTaskProcess
{
private:
public:
    /* data */
    int dataPort;
    int bufferSize;
    FileTransferTask taskInfo;
    bool appendTransfer;//是否开启断点续传
    CancelTaskPolicy cancelTaskPolicy;//取消策略 默认是=CancelTaskPolicy::DoNothing
    HashModel hashModel;//
    
    bool autoRetryDownload;//是否自动重新下载，当长时间没有进度更新时
    bool isCanRefreshToOut=false;//是否可以刷新到外部
public:
    FileTransferReceiverTaskProcess(int dataPort,int bufferSize,FileTransferTask &taskInfo);
     ~FileTransferReceiverTaskProcess();
    int Start();
    int Stop();
    void TryReleaseListResouse(std::wstring msg);
    int RequestCancel(CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    void SetControlSession(std::string sessionId,ClientHelper* client);
    void ClientTimeoutEvent(std::string msg);
    void ClientMsgReceiveEvent( ControlMsg msg );
    void Log(logLevel level,const wchar_t* msg);
    void Log(logLevel level,std::wstring msg);
    void DealCancelDownload(string json);
public: /* event */
    TaskErrorEvent taskErrorEvent=nullptr;
    ProgressChangeEvent progressChangeEvent=nullptr;
    TaskStateChangeEvent taskStateChangeEvent=nullptr;
    SubTaskStateChangeEvent subTaskStateChangeEvent=nullptr;
    LogEvent loger=nullptr;

private:
    bool isInit=false;
    bool isOnProgressChange=false;//是否正在进行通知
    std::string controlSessionId;
    std::thread housekeeperT;//管家 负责管理本任务的一些杂务 比如定期通知外部一些信息
    bool housekeeperT_IsExit=true;
    ClientHelper* controlClient;
    std::list<SubTask_Receive *>subTaskList;
    std::mutex subTaskListMtx;
    //ThreadsafeList<SubTask_Receive *>subTaskList;
    std::map<std::wstring,std::mutex*> hashMutex;
    //SimperSafeMap<std::wstring,FileState>doneSubTask;//已经完成的子任务的文件ID列表
    std::map<std::wstring, FileState>doneSubTask;//已经完成的子任务的文件ID列表
    std::mutex doneSubTasktMtx;
    //计算速率
    time_t lastProgressChangeTime;
    long long lastProgressChangeTransferLength;

    int autoRetryDownloadTimeout;//自动重新下载启用时，进度更新的超时时间
    int autoRetrySubTaskCount;//被重新下载的子任务的个数
private:
    void housekeeperExec();
    int SendFileTransferResponse();
    int SendCancelMsg();
    int SendInErrorToCancelMsg();
    int SendDownloadFileRequest(std::wstring taskId,const std::string socketSession,TransferFileInfo &fi);
    int SendMsg(ControlTopic topic,std::string msg);

    bool CreateTransferSubTask();
    ErrorCode CreateTransferSubTask(TransferFileInfo *fi);

    int SubTaskErrorEventCallback(SubFileTransferError e);//2.3.2	传输任务异常事件
    int SubProgressChangeEventCallback(SubFileTransferProgress e);//2.3.3	传输任务进度变化事件
    int SubTaskStateChangeEventCallback(SubFileTransferState e);//2.3.4	传输任务状态变化事件

    int CheckTaskProgress(int &hashChecked,HashCheckState &hashCheckeState);
    void CheckTaskState();
    void NoticeCurrentStateChange(TaskState state,HashCheckState hashCheckState);
    
    int SendFileTransferDone(TransferFileInfo &fi);
    int DelayProgressChange(bool isDelay=true);
    void DealFileDownloadEnd(std::string json);
    
    void DealTaskInBlockOutError(std::string json);
    void CheckHash(TransferFileInfo &fi);
    std::wstring GetFileHash(std::wstring path);
    int TryStopDoneSubTask();//清理已经完成的子任务
    int RetryDownloadSubTask();//检查子任务是否需要重新下载
    void DealFileTransferEnd();

    void LogEventCallback(logLevel level, std::wstring msg);
};



#endif