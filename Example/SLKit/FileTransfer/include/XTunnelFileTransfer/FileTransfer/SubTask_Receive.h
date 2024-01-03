#ifndef SubTask_Receive_H
#define SubTask_Receive_H
#include "FileTransferModel.h"
#include "string"
#include <thread>
#include <list>
#include "../Sockets/ClientHelper.h"
#include "JsonHelper.h"
#include "../Utils/tools.h"
#include <iostream>
#include <fstream>
#define receiveTempFlag L".tmp"
class SubTask_Receive
{
public:
    std::wstring taskId;
    TransferFileInfo fileInfo;
    std::wstring fileHashPath;
    bool appendTransfer;//是否开启断点续传
    time_t lastDownloadChangeTime;//最后一次下载进度变化的时间
    bool isRun = false;
private:
    /* data */
    
    std::string romoteIP;
    int romotePort;
    int bufferSize;
    ClientHelper* dataClient;
    std::ofstream* writeStream;
    long long receiveLength;
    SubFileTransferProgress receiveProg;
    time_t lastProgressChangeTime;
    time_t lastFlushTime;
    long long noFlushSize;
public:
    SubTask_Receive(std::wstring taskId, TransferFileInfo &fileInfo,std::string romoteIP, int romotePort,int bufferSize);
    // ~SubTask_Receive();
    int Start();
    int Stop();
    std::string GetSessionId();
    void ClientMsgReceiveEvent(const char* msgData, int msgLeng);
    long long GetFileOffSet();
    void CheckTaskState();//检查整个任务的状态，是否已经全部完成
public:
    SubTaskErrorEvent taskErrorEvent=nullptr;
    SubProgressChangeEvent progressChangeEvent=nullptr;
    SubTaskStateChangeEvent taskStateChangeEvent=nullptr;
    LogEvent loger=nullptr;
private:
    bool CreateWriteFileStream(std::wstring path);
    bool CloseFileStream();
    void ReleaseResources();
    void NoticeCurrentStateChange(FileState state);
    std::wstring GetHashFileName(std::wstring folderPath, std::wstring fileName, std::wstring FileExtenName, std::wstring hashStr);
    void Log(logLevel level,std::wstring msg);
};


#endif