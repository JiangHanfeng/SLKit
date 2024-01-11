#ifndef SubTask_Sender_H
#define SubTask_Sender_H
#include "FileTransferModel.h"
#include "string"
#include <thread>
#include <list>
#include "../Sockets/ClientHelper.h"
#include "JsonHelper.h"
#include "../Utils/tools.h"
#include "../Utils/MD5.h"
#include <iostream>
#include <fstream>
#include <future>
//using namespace std;
class SubTask_Sender
{
public:
    std::wstring taskId;
    TransferFileInfo fileInfo;
    LogEvent loger=nullptr;
private:
    /* data */
    std::string remoteIP;
    int remotePort;
    int bufferSize;
    std::string controlSessionId;
    ClientHelper* dataClient;
    bool isStart;
    std::thread dataTransferT;
    bool dataTransferT_IsExit=true;
    // std::future<int> dataTransferT;
    std::future<void> msgNoticeT;
    ifstream* readStream;
    time_t lastProgressChangeTime;
    MD5 md5;//计算发送的数据的md5值
    std::string md5String;
public:
    SubTask_Sender(std::wstring taskId, TransferFileInfo &fileInfo,std::string remoteIP, int remotePort,int bufferSize);
    // ~SubTask_Receive();
    int Start();
    int Stop();
    void SetControlSession(std::string sessionId,ClientHelper* client);
    std::string GetMd5();
    int SendFileData(void *ptrT);
public:
    SubTaskErrorEvent taskErrorEvent=nullptr;
    SubProgressChangeEvent progressChangeEvent=nullptr;
    SubTaskStateChangeEvent taskStateChangeEvent=nullptr;
    void Log(logLevel level,const wchar_t* msg);
    void Log(logLevel level,std::wstring msg);
private :
    bool CreateReadFileStream();
    bool CloseFileStream();
    void ReleaseResources();
    int SendData(char* buffer, int length);
    void NoticeCurrentStateChange(FileState state);
};



#endif