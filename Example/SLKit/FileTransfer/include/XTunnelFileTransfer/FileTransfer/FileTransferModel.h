#ifndef INCLUDE_FILETRANSFERMODEL_H_
#define INCLUDE_FILETRANSFERMODEL_H_
#include <string>
#include <list>
#define MinBufferSize 1024*4//定义最小的buffer大小是4K，防呆，毕竟小于这个值连控制消息都可能传输不过去
//using namespace std;

enum ErrorCode
{
    NoError = -2,//未设置状态
    Error = -99,//错误，初始值
    NetworkError = 1,//网络错误
    IOError = 2,//文件读写错误
    FileNotExist = 3,//目标文件不存在
    FolderNotExist = 4,//目标文件夹不存在
    UnInit = 5,//没有初始化
    Inited = 6,//已经初始化过了
    ConnectUnInit = 7,//连接未初始化
    FileReadLengthAbnormal = 8,//文件大小读取异常
    TaskIsExist = 9,//任务已经存在，多用与任务重传时的检查
    FileIsExist = 10,//文件已经存在
    FileIsCreated=11,//文件已经创建,文件大小为0时使用，接收端只需要创建文件，不需要写入数据
};
enum ControlTopic
{
    FileTransferRequest=0,//文件传输请求
    FileTransferConfirming=1,//文件传输请求的回应
    FileDownloadRequest=2,//文件下载
    CancelDownload=3,//取消下载
    CancelDownloadResponse=4,//取消下载的回应
    FileDownloadEnd=5,//下载成功
    TaskInBlockOutError=6,//IO异常，请求取消传输
    FileTransferEnd=7,//文件传输任务完成，发送端发送结束后，发出此消息
    MsgConfirm_FileTransferRequest =8,//消息确认，收到重要消息后，给出回复
    MsgLine=99,//消息通道，与文件传输无关，辅助通道
};
/// @brief （物理）设备类型
enum PhysicalDeviceType
{
    NONE,
    IWB,
    MC,
    PC
};
enum TaskType
{
    sender=0,//发送任务
    receiver=1,//接收任务
};
enum TaskState
{
    Waiting=0,//等待
    CheckLocalFileInfo=1,//检查本地文件信息
    Confirming ,//确认
    Reject,//拒绝
    Suspended,//暂停
    Transmitting,//传输中
    TransferCancel,//取消传输，被动取消方用这个
    TransferDone,//传输完成
    Cancel ,//主动取消方，使用这个状态
    Oversized,
    TransferNoFile,//没有可以传输的文件
    RemoteInError,//对方进入阻断性错误导致任务终止
    CancelToRe,//取消任务，等待对方重传
    InError=99,//异常
};
enum ResponseType
{
    confirming=0,
    reject=1,
    suspended=2,
    cancel=3,
    oversized=4
};
enum CoverStrategy
{
    Skip=0,//不覆盖，如果已经有同名文件就跳过
    ReWrite=1,//重写，删除已经存在的同名文件，然后重新创建和写入
    Append=2,//追加，如果已经有同名文件，则将数据追加到后面
};
//注意： 同一程序中不能定义同类型名的枚举类型；不同枚举类型的枚举元素不能同名
enum FileState
{
    f_Waiting = 0,//等待下载
    f_Reject=1,//拒绝
    f_Suspended,//暂停
    f_Transmitting,//传输中
    f_TransferCancel,//取消
    f_TransferDone,//完成
    f_NeedRetry,//需要重新下载
    f_Error,//错误
};
/// @brief hash校验状态
enum HashCheckState
{
    Hash_Wait=0,//0,未开始计算；
    Hash_Received=1,//1，已经收到Hash码；
    Hash_Checking=2,//2，正在进行hash校验；
    Hash_Success=3,//3，hash校验成功；
    Hash_CheckFailed=4,//4，hash校验不匹配；
    Hash_CheckError=5,//5，hash校验异常
    Hash_PartCheckFailed=6,//6，hash校验部分不匹配；
    Hash_PartCheckError=7,//7，hash校验部分异常
};
enum HashModel
{
    None=0,//无hash
    FullHash=1,//全量hash
    FastHash=2,///快速hash
};
/// @brief 取消任务策略
enum CancelTaskPolicy
{
    DoNothing=0,//默认策略，直接取消任务即可
    DeleteUnfinished,//删除未完成的文件
    DeleteTaskFile,//删除任务传输的文件，包括已经完成和未完成的文件
};
inline std::wstring GetEnumString(TaskState state)
{
    std::wstring msg=L"未知状态"+std::to_wstring(state);
    switch (state)
    {
        case TaskState::Cancel:msg=L"主动取消";break;
        case TaskState::Waiting:msg=L"等待";break;
        case TaskState::CheckLocalFileInfo:msg=L"检查本地文件信息";break;
        case TaskState::Confirming:msg=L"确认";break;
        case TaskState::Reject:msg=L"拒绝";break;
        case TaskState::Suspended:msg=L"暂停";break;
        case TaskState::Transmitting:msg=L"传输中";break;
        case TaskState::TransferCancel:msg=L"被动取消传输";break;
        case TaskState::TransferDone:msg=L"传输完成";break;
        case TaskState::Oversized:msg=L"重写";break;
        case TaskState::TransferNoFile:msg=L"没有可以传输的文件";break;//没有可以传输的文件
        case TaskState::RemoteInError:msg=L"远端错误";break;
        case TaskState::InError:msg=L"异常";break;
    default:
        msg=L"未知状态"+std::to_wstring(state);
        break;
    }
    return msg;
}
struct TransferFileInfo
{
    /* data */
    std::wstring id;//每个文件的唯一标识
    std::wstring name;//文件名，不包括扩展名
    std::wstring extensionName;//扩展名
    long long size;//文件大小，单位字节
    std::wstring hashCode;//文件hash值，可以在任务请求时赋值，也可以在任务开始后赋值
    HashCheckState hashCodeCheckStat;//hash校验状态， 0,未开始计算；1，已经收到Hash码；2，正在进行hash校验；3，hash校验成功；4，hash校验不匹配；5，hash校验异常
    std::wstring path;//【不传输】文件本地路径，控制消息里不传此字段或者为空
    std::wstring relativePath;//相对路径，例子1：比如要发送的文件夹为aaa，里面包含另一个子文件夹bbb，子文件夹里包含ccc.txt文件，则相对路径为bbb;
    FileState stat;//当前状态：Waiting = 0/Reject/Suspended/Transmitting/TransferCancel/TransferDone/Error，控制消息里一般用作此文件的目标状态，比如取消传输时值应该是TransferCancel，默认为0
    ErrorCode errorCode;//错误码，当任务状态为异常时，可以通过错误码判断错误原因
    time_t doneTime;//文件传输结束的时间，默认未0；
    int progress;//传输进度，取值0-100，默认0
    long long transferLength;//已经传输的长度，程序内部使用，控制消息里不传此字段或者为空
    long long offSet;//偏移，即从哪个字节开始传输此文件，默认为0 

};

struct FileTransferRequestInfo
{
    /* data */
    std::wstring taskId;//每个任务的唯一标识
    std::wstring senderIp;
    std::wstring receiveIp;//
    std::wstring senderDeviceId;//发送端唯一标识，设备ID
    std::wstring receiveDeviceId;//接收端唯一标识，设备ID
    std::wstring senderDeviceName;//发送端设备名称，如果发送端没有设置，则此值等于发送端设备ID
    std::wstring receiveDeviceName;//接收端设备名称，如果接收端没有设置，则此值等于接收端设备ID
    PhysicalDeviceType senderDeviceType;//发送放设备类型，默认为未设置
    PhysicalDeviceType receiveDeviceType;//接收方设备类型，默认为未设置
    long bufferSize;//任务的缓冲区大小，单位字节
    int transferType;//File=0,folder=1
    std::list<std::wstring> nameList;//传输列表，如果是文件夹传输，则为传输的文件夹列表；如果是文件传输，则为传输的文件列表；比如传输文件夹aaa，则为[{“aaa”}]
    std::list<TransferFileInfo> fileList;//传输的文件的集合，包含本次传输的所有文件的详细信息，结构见本节
    std::wstring thumbnail;//缩略图的base64，选填
    //后补的字段
    int senderControlPort;//发送端控制端口
    int senderDataPort;//发送端数据端口
    int receiveControlPort;//接收端控制端口
    int receiveDataPort;//接收端数据端口
    std::wstring pathRoot;//发送端的基准路径，不传输使用
    std::wstring extraJson;//附加拓展字段，应当为一个json,默认为空
};
struct FileTransferResponseInfo
{
    /* data */
    std::wstring taskId;//每个任务的唯一标识
    std::wstring senderDeviceId;//发送端唯一标识，设备ID
    std::wstring receiveDeviceId;//接收端唯一标识，设备ID
    std::wstring receiveDeviceName;//接收端设备名称，如果接收端没有设置，则值为接收端ID
    PhysicalDeviceType receiveDeviceType;//接收方设备类型，默认为未设置
    ResponseType type;//回应的类型，//Confirming = 0/Reject = 1/Suspended = 2/Cancel = 3/ Oversized=4
    long long maxFileSize;//接收端最大接收的文件的大小，单位字节
    long bufferSize;//接收任务的缓冲区大小，单位字节
};

struct FileTransferTask
{
    /* data */
    // std::string taskId;//每个任务的唯一标识
    TaskState stat;//传输状态
    ErrorCode errorCode;//错误码，当任务状态为异常时，可以通过错误码判断错误原因
    HashCheckState hashCodeCheckStat;//hash校验状态
    TaskType type;//发送任务为0，接收任务为1
    // std::string remoteDeviceId;//远端设备ID
    // std::string remoteIP;//远端设备的IP
    int remoteControlPort;//远端设备使用的端口
    int remoteDataPort;//远端设备使用的端口
    int localPort;//本地设备使用的端口
    long bufferSize;//任务的缓冲区大小，应当是协商后的大小，单位字节,requestInfo信息中也有bufferSize字段，是发送端建议的值，
    int progress;//任务进度，按照大小计算进度，取值0-100
    FileTransferRequestInfo requestInfo;//任务请求的具体信息
};
struct TransferFileControlRequest
{
    std::wstring taskId;//每个任务的唯一标识
    std::string socketSession;//目标Socket的标识，建议使用IP+Port，在本实体中和fileInfo对应
    TransferFileInfo fileInfo;//文件信息； 没必要传那么多
    CancelTaskPolicy cancelTaskPolicy;//任务取消策略，默认为None 不做操作
};

struct FileTransferError
{
    /* data */
    std::wstring taskId;//每个任务的唯一标识
    int errorCode;//错误码
    int type;//发送任务为0，接收任务为1
};

struct FileTransferState
{
    std::wstring taskId;//每个任务的唯一标识
    TaskState stat;//传输状态
    ErrorCode errorCode;//错误码，当任务状态为异常时，可以通过错误码判断错误原因
    TaskType type;//发送任务为0，接收任务为1
    HashCheckState hashCodeCheckStat;//hash校验状态
};
struct SubFileTransferError
{
    /* data */
    std::wstring taskId;//每个任务的唯一标识
    std::wstring fileId;//每个任务的唯一标识
    int errorCode;//错误码
    int type;//发送任务为0，接收任务为1
};
struct SubFileTransferProgress
{
    /* data */
    std::wstring taskId;//每个任务的唯一标识
    std::wstring fileId;//每个任务的唯一标识
    int progress;//传输进度
    long long transferLength;//已经传输的文件大小
    int type;//发送任务为0，接收任务为1
};
struct FileTransferProgress
{
    /* data */
    std::wstring taskId;//每个任务的唯一标识
    int progress;//传输进度
    long long transferLength;//已经传输的文件大小
    long long transferRate;//传输速率 bit/sec
    TaskType type;//发送任务为0，接收任务为1
    std::list<SubFileTransferProgress> subTaskProgress;
};
struct SubFileTransferState
{
    std::wstring taskId;//每个任务的唯一标识
    std::wstring fileId;//每个任务的唯一标识
    FileState stat;//传输状态
    TaskType type;//发送任务为0，接收任务为1
    ErrorCode errorCode;//错误码，当任务状态为异常时，可以通过错误码判断错误原因
};
struct LineMsgInfo
{
    std::wstring lineId;
    std::wstring msg;
};
struct ControlMsg
{
    ControlTopic topic;//当前控制消息的类型
    std::string modelJson;//具体数据的Json，根据topic进行不同的解析
};



// typedef  int(*TransferRequestEvent)(FileTransferRequestInfo e);//文件传输请求事件
// typedef  int(*TaskErrorEvent)(FileTransferError e);//2.3.2	传输任务异常事件
// typedef  int(*ProgressChangeEvent)(FileTransferProgress e);//2.3.3	传输任务进度变化事件
// typedef  int(*TaskStateChangeEvent)(FileTransferState e);//2.3.4	传输任务状态变化事件
#include <functional>
using TransferRequestEvent=std::function<int(FileTransferRequestInfo)>;//文件传输请求事件
using TaskErrorEvent=std::function<int(FileTransferError)>;//2.3.2	传输任务异常事件
using ProgressChangeEvent=std::function<int(FileTransferProgress)>;//2.3.3	传输任务进度变化事件
using TaskStateChangeEvent  = std::function<int(FileTransferState)>;//2.3.4	传输任务状态变化事件
using LineMsgEvent  = std::function<int(LineMsgInfo)>;//2.3.4	传输任务状态变化事件

// typedef function<void(int)> TaskStateChangeEvent2;
using DownloadFileRequestEvent = std::function<int(TransferFileControlRequest)>;//文件下载请求事件

using SubTaskErrorEvent= std::function<int(SubFileTransferError)>;//	子任务传输任务异常事件
using SubProgressChangeEvent=std::function<int(SubFileTransferProgress)>;//	子任务传输任务进度变化事件
using SubTaskStateChangeEvent  = std::function<int(SubFileTransferState)>;//子任务传输任务状态变化事件
enum logLevel
{
    info=0,
    debug=1,
    warning=2,
    error=3
};
using LogEvent=std::function<void(logLevel,const wchar_t*)>;//日志

inline std::wstring GetEnumString(logLevel state)
{
    std::wstring msg=L"未知状态："+ std::to_wstring(state);
    switch (state)
    {
        case logLevel::info:msg=L"信息";break;
        case logLevel::debug :msg=L"调试";break;
        case logLevel::warning :msg=L"警告";break;
        case logLevel::error :msg=L"错误";break;
        default:
            break;
    }
    return msg;
}
#endif