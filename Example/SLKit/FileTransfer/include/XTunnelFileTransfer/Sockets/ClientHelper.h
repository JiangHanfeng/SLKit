#ifndef INCLUDE_CLIENTHELPER_H_
#define INCLUDE_CLIENTHELPER_H_
#include "TCPClient.h"
#include <thread>
#include "../Utils/tools.h"
typedef  int(*MSG_CALLBACK)(void*,std::string sessionId,const char* msgData, int msgLeng);
#define ControlMsgBeginFlag "XT$$"
#define ControlMsgEndFlag "XT&&";
#define HeartbeatMsg "hello"
#define HeartbeatTimeoutFlag "timeout"
#define SendTimeout 6000
#define SetSendTimeout true
#define ReceiveTimeout 250
class ClientHelper
{
public:
    void* ptr_handle=nullptr;
    std::string localIp;//本机使用的IP
    std::string remoteIp;//目标IP
    int localPort;//本地端口
    int remotePort;//目标端口
    int bufferSize;//数据收发的buffer
    int timeOut;//超时时间
    bool isStart;
    bool isTimeout;//当前是否已经超时
    std::string sessionId;
    CTCPClient* m_pTCPClient=nullptr;
    MSG_CALLBACK callback=nullptr;
    SocketLog loger=nullptr;
public:
    ClientHelper(std::string ip,int port,int bufferSize,int timeOut=6,bool isControl=false);
    bool SetCallback(void* handle,MSG_CALLBACK invokeFunc);
    /// @brief 开启连接
    /// @return 
    int Connect();
    int Connect(CTCPClient* client);
    /// @brief 关闭连接 
    /// @return 
    int DisConnect();

    void HandleReceive();
    void HandleReceiveControlMsg();//接收控制消息，保证消息完整传输
    
    int Send(std::string msg);
    int Send(const char* pData, const size_t uSize);
    std::string GetSessionId();
    bool GetLocalIPAndPort(std::string &ip,int &port);
    std::string GetServerAcceptClientSessionId();
    bool isSendHeartbeat;
private:
    std::thread receiveT;
    std::thread heartbeatT;
    time_t lastReceiveHeartbeatTime;
    bool isCheckMsgFlag=false;//是否检查消息开始和结束标记
private:
    void Log(const wchar_t* msg);
    void Log(std::wstring msg);
    void SendHeartbeat();
    bool CheckIsTimeout();
    int GetControlMsg(char* szRcvBuffer,int &dataLength, std::list<string> &resultList,const char* beginFlag,int beginFlagLength,const char* endFlag,int endFlagLength);
};

#endif