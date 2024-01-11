#ifndef INCLUDE_SERVERHELPER_H_
#define INCLUDE_SERVERHELPER_H_
#include "TCPServer.h"
#include "TCPClient.h"
#include <list>
#include <map>
#include <thread>
#include "ClientHelper.h"
#include "../Utils/tools.h"
#include "../Utils/SimperSafeMap.h"
// typedef  int(*SERVER_MSG_CALLBACK)(void*,std::string sessionId , char* msgData, int msgLeng);
class ServerHelper
{
private:
    /* data */
    bool isCheckMsgFlag=false;//是否检查消息开始和结束标记
public:
    void* ptr_handle=nullptr;
    bool isRun;
    // int socketServer;//socket承载
    std::string ip;//目标IP
    int port;//目标端口
    int bufferSize;//数据收发的buffer
    int timeOut;//超时时间
    std::wstring serviceGuid;//
    // int maxClientNum;//挂起状态的最大连接数
    // socket缓冲队列大小
    const int QUEUE_SIZE = 1024;
    // bool isStart;
    // std::list<int>socketList;
    // std::list<ASocket::SocketInfo> clientList;
    SimperSafeMap<std::string,ClientHelper*> clientList;

    SocketLog loger=nullptr;
private:
    CTCPServer* m_pTCPServer=nullptr;
    MSG_CALLBACK callback=nullptr;
    std::thread listtenT;
    bool listtenT_IsExit = true;
    // std::thread receiveT;
public:
    ServerHelper(void* handle,int port,int bufferSize,int timeOut=6,bool isCheckMsgFlag=false);
    bool SetCallback(MSG_CALLBACK invokeFunc);
    //开启服务
    int Start();
    /// @brief 关闭服务
    /// @return 
    int Stop();
    /// @brief 关闭一个socket客户端
    /// @param sessionId 
    /// @return 
    int DisConnect(std::string sessionId);
    void AcceptConnect();
    //void HandleReceive(ASocket::SocketInfo si);
    int Send(std::string sessionId,std::string msg);
    ClientHelper* MoveSession(std::string sessionId);
    std::string GetSessionId(ASocket::SocketInfo si);
    int GetIP(std::string sessionId,std::string &ip/*,int &port*/);

    int ClientMsgReceiveEvent(std::string sessionId,const char* msgData, int msgLeng);
private:
    void Log(const wchar_t* msg);
    void Log(std::wstring msg);
    void ControlClientPortLog(std::wstring msg);
};
// ServerHelper::~ServerHelper()
// {
// }


#endif