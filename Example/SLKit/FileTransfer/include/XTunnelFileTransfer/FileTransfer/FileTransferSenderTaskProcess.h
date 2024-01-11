#ifndef INCLUDE_FileTransferTask_H_
#define INCLUDE_FileTransferTask_H_
#include "FileTransferModel.h"
#include "string"
#include <thread>
#include <list>
#include "../Sockets/ClientHelper.h"
#include "JsonHelper.h"
#include "../Utils/tools.h"
#include "../Utils/SimperSafeMap.h"
#include "SubTask_Sender.h"
#include <future>
#define Msg_Confirm_Timeout 4//消息确认的超时时间，超过这个时间没有回复就认为没有收到这个消息
class FileTransferSenderTaskProcess
{
public:
    /* data */
    FileTransferTask taskInfo;
    bool appendTransfer;//是否开启断点续传
    CancelTaskPolicy cancelTaskPolicy;//取消策略 默认是=CancelTaskPolicy::DoNothing
    HashModel hashModel;//
    int socketTimeout;//socket心跳超时时间，单位秒，默认6秒
    bool isCanRefreshToOut = false;//是否可以刷新到外部
public:
    FileTransferSenderTaskProcess(FileTransferTask &taskInfo);
     ~FileTransferSenderTaskProcess();
    int Start();
    int Stop();
    void TryReleaseListResouse(std::wstring msg);
    int RequestCancel(CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    int SendFileTransferRequest();
    
    int SendFile(ClientHelper* client,TransferFileControlRequest fileRequest);
    int SendCancelMsg();
    int SendMsg(ControlTopic topic,std::string msg);
    void ClientTimeoutEvent(std::string msg);
    void MsgTimeoutEvent(std::string msg);
    void ClientMsgReceiveEvent(ControlMsg msg);
    void Log(logLevel level,const wchar_t* msg);
    void Log(logLevel level,std::wstring msg);
public: /* event */
    TaskErrorEvent taskErrorEvent=nullptr;
    ProgressChangeEvent progressChangeEvent=nullptr;
    TaskStateChangeEvent taskStateChangeEvent=nullptr;
    // TaskStateChangeEvent2 taskStateChangeEvent2;
    DownloadFileRequestEvent downloadFileRequestEvent=nullptr; 
    SubTaskStateChangeEvent subTaskStateChangeEvent=nullptr;
    LogEvent loger=nullptr;
private:
    ClientHelper* controlClient;
    bool isInit=false;
    std::thread housekeeperT;//管家 负责管理本任务的一些杂务 比如定期通知外部一些信息
    bool housekeeperT_IsExit = true;
    std::future<int> housekeeperT_create;//创建管家，负责当前任务的创建流程
    bool isOnProgressChange=false;//是否正在进行通知
    std::list<SubTask_Sender *>subTaskList;
    std::mutex subTaskListMtx;
    //SimperSafeMap<std::wstring,FileState>doneSubTask;//已经完成的子任务的文件ID列表
    std::map<std::wstring,FileState>doneSubTask;//已经完成的子任务的文件ID列表
    std::mutex doneSubTasktMtx;

    //计算速率
    time_t lastProgressChangeTime;
    long long lastProgressChangeTransferLength;
    //传输请求发出的时间
    time_t taskRequestTime;
    bool msgConfirming_FileTransferRequest = false;
private:
    int ProcessCreate(void *ptrT);
    void housekeeperExec();
    int DealMsgConfirming_FileTransferRequest(std::string json);
    int DealFileTransferConfirming(std::string json);
    int DealFileDownloadRequest(std::string json);
    void DealFileDownloadEnd(std::string json);
    void DealCancelDownload(std::string json);
    void DealTaskInBlockOutError(std::string json);
    int SubTaskErrorEventCallback(SubFileTransferError e);//2.3.2	传输任务异常事件
    int SubProgressChangeEventCallback(SubFileTransferProgress e);//2.3.3	传输任务进度变化事件
    int SubTaskStateChangeEventCallback(SubFileTransferState e);//2.3.4	传输任务状态变化事件
    int CheckTaskProgress();
    std::wstring GetFileHash(std::wstring path);
    void CheckTaskState();//检查整个任务的状态，是否已经全部完成
    void NoticeCurrentStateChange(TaskState state);
    int SendFileTransferDone(TransferFileInfo &fi);
    TaskState getType(ResponseType type);
    int DelayProgressChange();
    int TryStopDoneSubTask();//清理已经完成的子任务
    /// @brief 获取指定文件路径的文件信息
    /// @param basePath 当前文件相对于基目录的路径，用于拼装文件的相对路径
    /// @param path 文件的绝对路径
    /// @param fileInfo 承载文件信息
    /// @return  获取结果，成功=0，失败!=0
    int GetTransferFileInfo(std::wstring basePath, std::wstring path,TransferFileInfo &fileInfo,bool hash=false);
    int SendInErrorToCancelMsg();
    void SendTaskEnd();
    void ControlPortLog(const wchar_t* msg);
    void SubTaskLog(logLevel level,const wchar_t* msg);
    void PrintfTaskFileInfo(FileTransferRequestInfo requestInfo, bool printfNameList, bool printfFileList);
};


#endif