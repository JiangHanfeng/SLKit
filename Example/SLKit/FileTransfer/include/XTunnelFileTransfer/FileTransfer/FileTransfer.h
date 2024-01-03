

#ifndef INCLUDE_FILETRANSFER_H_
#define INCLUDE_FILETRANSFER_H_
#include "string"
#include <thread>
#include <list>
#include <map>
#include "FileTransferModel.h"
#include "../Sockets/ServerHelper.h"
#include "FileTransferSenderTaskProcess.h"
#include "FileTransferReceiverTaskProcess.h"
#include "ReceiveFileInfoUnit.h"
#include "../Utils/tools.h"
#include <sys/stat.h>//使用stat函数获取文件信息
#include <ostream>
#include <future>
#define sdk_version L"0.1.3.18"
#define SocketTimeout 6

#define OrderTaskIdFlag L"__"
class FileTransfer
{
public:/* data */
    std::wstring deviceId;
    std::wstring deviceName;//初始化时设置，支持后续动态修改，但是修改只在后续任务生效，已经在进行的任务不会自动修改
    PhysicalDeviceType deviceType;//设备类型，详情参见
    int controlPort;
    int dataPort;
    long bufferSize;//socket传输的缓冲区大小，一般接收端和发送端进行比较双方的bufferSize协商取小，支持动态修改，但是只对之后的任务生效
    int maxFileSize;//类型：long，大小超过最大限度的文件拒绝接收。
    int maxDownload;//最大同时传输的文件的大小，用以控制传输速度，默认值为5
    bool appendTransfer;//是否开启断点续传
    int socketTimeout;//socket心跳超时时间，单位秒，默认6秒
    std::list<FileTransferTask> receiveTaskList;
    std::list<FileTransferTask> senderTaskList;
    std::map<std::string,FileTransferRequestInfo>fileTransferRequestList;
    std::map<std::wstring, ClientHelper*>MsgLineList;
    std::mutex MsgLineListMutex;
public:/* function */
    FileTransfer(/* args */);
    virtual ~FileTransfer();
    int Init(int controlPort,int dataPort,std::wstring deviceId,int buferSize=1024*1024*2,std::wstring deviceName=L"",int deviceType=0,int timeout=6);
    int UnInit();
    void SetDeviceName(std::wstring deviceName = L"");
    int SetCallback(LogEvent loger); 
    int SetCallback(TransferRequestEvent loger); 
    int SetCallback(ProgressChangeEvent loger); 
    int SetCallback(TaskStateChangeEvent loger); 
    int SetCallback(TaskErrorEvent loger); 
    int SetCallback(LineMsgEvent event);
    /// <summary>
    /// 请求传输文件
    /// </summary>
    /// <param name="ip">对方的IP</param>
    /// <param name="controlPort">对方的控制端口</param>
    /// <param name="dataPort">对方的数据端口</param>
    /// <param name="transferType">文件传输类型 0文件 1文件夹 2文件和文件夹</param>
    /// <param name="nameList">要传输的文件或文件夹的路径列表</param>
    /// <param name="taskId">任务ID，创建任务成功后赋值，创建任务失败会为空</param>
    /// <returns>0为创建任务成功</returns>
    //int RequestFileTransfer(std::wstring ip,int transferType,std::list<std::wstring> nameList,std::wstring &taskId);
    int RequestFileTransfer(std::wstring ip,int controlPort,int dataPort,int transferType,std::list<std::wstring> nameList,std::wstring &taskId);
    int CancelFileTransfer (std::wstring taskId_outward, std::wstring fileId=L"",CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    // int ReDownloadFile (std::wstring taskId_outward, std::wstring fileId,std::wstring savePath);
    int StopAll(CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    bool HasRunTransferTask();
    std::list<FileTransferTask>GetSenderTaskList();
    std::list<FileTransferTask>GetReceiveTaskList();
    int GetTask (std::wstring taskId_outward,FileTransferTask &taskInfo);
    int FileTransferResponse(std::wstring taskId_outward, int type,std::wstring savePath,int coverStrategy);
    /// @brief 如果任务因为网络问题异常终止，可以使用此接口重新开启此任务，任务ID不变
    /// @param taskId 要重新开始的任务的ID
    /// @param ip 目标设备的IP，不为空时表示更新IP
    /// @return 
    int ReTask(std::wstring taskId_outward,std::wstring ip=L"");
    /// <summary>
    /// 使用通讯链路发送消息
    /// </summary>
    /// <param name="lineId"></param>
    /// <param name="msg"></param>
    /// <returns></returns>
    int MsgLineSend(std::wstring lineId, std::wstring ip,int port, std::wstring msg);
public://不要对外发布
    void ServerMsgReceiveEvent(std::string sessionId , ControlMsg msg );
    //void DealEvent();
    int Monitor();//void *ptrT
    void Log(logLevel level,const wchar_t* msg);
    void Log(logLevel level,std::wstring msg);
    void ControlPortLog(const wchar_t* msg);
    void DataPortLog(const wchar_t* msg);
public: /* event */
    TransferRequestEvent transferRequestEvent=nullptr;
    TaskErrorEvent taskErrorEvent=nullptr;
    ProgressChangeEvent progressChangeEvent=nullptr;
    TaskStateChangeEvent taskStateChangeEvent=nullptr;
    LogEvent loger=nullptr;
    LineMsgEvent lineMsgEvent =nullptr;
private:
    /* data */
    bool isInit=false;
    std::map<std::string,std::future<int>> transferRequestList;
    std::thread housekeeperT;//管家 负责管理本任务的一些杂务 比如定期通知外部一些信息
    ServerHelper* controlServer=nullptr;
    ServerHelper* dataServer=nullptr;

    std::map<std::wstring,FileTransferSenderTaskProcess*> senderProcess;
    int senderTaskOrder = 0;
    std::map<std::wstring,FileTransferReceiverTaskProcess*> receiverProcess;
    int receiverTaskOrder = 0;

    std::mutex stopReceiveTaskMtx;

    SimperSafeMap<std::wstring,TaskState>doneSubSenderTask;//已经完成的子任务的文件ID列表
    SimperSafeMap<std::wstring,TaskState>doneSubReceiveTask;//已经完成的子任务的文件ID列表
    SimperSafeMap<std::wstring,std::wstring>taskSavePathDict;//任务保存路径

    SimperSafeMap<std::wstring, time_t>cancelTaskDict;//已经取消的任务的列表
private:
    
    int StopTask(std::wstring taskId,CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    int StopSenderTask(std::wstring taskId,CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    int StopReceiveTask(std::wstring taskId,CancelTaskPolicy policy=CancelTaskPolicy::DoNothing);
    int StopReceiveTaskToWaitingRe(std::wstring taskId);
    int ExecCancelTaskPolicy(std::wstring taskId,CancelTaskPolicy cancelTaskPolicy);
    void LogEventCallback(logLevel level,std::wstring msg);
    /* function */
    //std::list<TransferFileInfo> GetTaskSendFileList(int fileTransferType, std::wstring path);
    
    //std::list<TransferFileInfo> GetAllFilesInFolder(std::wstring folderPath);
    // std::list<TransferFileInfo> GetAllFilesInFolder(std::string basePath,DirectoryInfo root);
    //std::string GetFileHashAndLength(std::wstring path);
    int CreateSenderProcess(FileTransferRequestInfo &request);
    int CreateReceiverProcess(std::string sessionId ,TaskState responseType,FileTransferRequestInfo &model,const std::wstring &downloadPath);
    int CreateReceiverProcess_re(std::string sessionId , TaskState responseType,FileTransferRequestInfo mode);

    void DealCancelDownload(std::string sessionId,std::string json);
    void DealFileTransferRequest(std::string sessionId , std::string requestJson);
    void DealMsgLine(std::string sessionId , std::string json);
    void AutoFileTransferResponse(std::string sessionId , std::string requestJson);
    int SendControlsMsg(std::string sessionId,std::string json);
    int SendFileTransferRequestMsgConfirm(std::string sessionId, FileTransferRequestInfo request);//发送请求
    int GetTaskReceiveFileList(std::wstring taskId,std::list<TransferFileInfo> &fileList,const int transferType,const std::wstring &downloadPath);

    // int TransferRequestEventCallback(FileTransferRequestInfo e);//文件传输请求事件
    int TaskErrorEventCallback(FileTransferError e);//2.3.2	传输任务异常事件
    int ProgressChangeEventCallback(FileTransferProgress e);//2.3.3	传输任务进度变化事件
    int TaskStateChangeEventCallback(FileTransferState e);//2.3.4	传输任务状态变化事件
    int DownloadFileRequestEventCallback(TransferFileControlRequest e);//文件下载请求事件，需要外部找到相关socket后协助调用相关发送函数
    int SubTaskStateChangeEventCallback(SubFileTransferState e);//子任务状态变化事件

    TaskState getType(ResponseType type);
    std::wstring getTaskTypePrompt(TaskState state);
    int TryStopDoneSubTask();//清理已经完成的子任务
    void NoticeCurrentStateChange(TaskType type,std::wstring taskId,TaskState state,ErrorCode errorCode,HashCheckState hashCheckState, std::wstring targetDeviceName);
    void ReleaseClientSocket(ClientHelper* client);
    int SendCancelMsg(std::wstring taskId, CancelTaskPolicy cancelTaskPolicy);

    std::wstring GetOrderTaskId(TaskType taskType, std::wstring taskId);
    std::wstring GetTaskId(std::wstring orderTaskId);

    ClientHelper* GetClient(std::wstring sessionId, std::wstring ip, int port);
    bool HasMsgLine(std::wstring lineId);
    void SetMsgLineReceive(ClientHelper* client);
};



#endif