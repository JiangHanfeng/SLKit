/*
* @file TCPClient.h
* @brief wrapper for TCP client
*
* @author Mohamed Amine Mzoughi <mohamed-amine.mzoughi@laposte.net>
* @date 2013-05-11
*/

#ifndef INCLUDE_TCPCLIENT_H_
#define INCLUDE_TCPCLIENT_H_
#define IOS

#include <algorithm>
#include <cstddef>   // size_t
#include <cstdlib>
#include <cstring>   // strerror, strlen, memcpy, strcpy
#include <ctime>
#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string>
#include <vector>

#include "Socket.h"
// /usr/include/signal.h
#include <signal.h>
#ifndef WINDOWS
#include <sys/types.h>   
#include <sys/socket.h>
#include <libgen.h>
#ifdef IOS
#include <netinet/tcp.h>
#else
#include <linux/tcp.h>
#endif
#include <netinet/in.h>
#include <netinet/ip.h>
#define SOCKET_ERROR            (-1)
#ifdef IOS
#define tcp_info tcp_connection_info
#define TCP_INFO 11
#endif
#endif
#define SendTimeout 6000
#define ConnectTimeOut 6000 //连接超时时间 单位毫秒
using SocketLog=std::function<void(const wchar_t*)>;//日志
class CTCPSSLClient;
// typedef  int(*MSG_CALLBACK)(void*,std::string sessionId,char* msgData, int msgLeng);
class CTCPClient : public ASocket
{
   friend class CTCPSSLClient;

public:
   explicit CTCPClient(const LogFnCallback oLogger, const SettingsFlag eSettings = ALL_FLAGS);
   ~CTCPClient() override;

   // copy constructor and assignment operator are disabled
   CTCPClient(const CTCPClient&) = delete;
   CTCPClient& operator=(const CTCPClient&) = delete;

// #ifdef WINDOWS
   bool Connect(const std::string strServer, const int strPort);// connect to a TCP server
// #else
//    bool Connect(const std::string strServer, const std::string strPort);// connect to a TCP server
// #endif // WINDOWS

   bool SetSocket(Socket connectSocket,const std::string strServer, const std::string strPort);
   bool Disconnect(); // disconnect from the TCP server
   bool Send(const char* pData, const size_t uSize) ; // send data to a TCP server
   bool Send(const std::string& strData) ;
   bool Send(const std::vector<char>& Data) ;
   int  Receive(char* pData, const size_t uSize, bool bReadFully = true) ;

   // To disable timeout, set msec_timeout to 0.
   bool SetRcvTimeout(unsigned int msec_timeout);
   bool SetSndTimeout(unsigned int msec_timeout);
#ifndef WINDOWS
   bool SetRcvTimeout(struct timeval Timeout);
   bool SetSndTimeout(struct timeval Timeout);
#endif

   bool IsConnected() const { return m_eStatus == CONNECTED; }

   Socket GetSocketDescriptor() const { return m_ConnectSocket; }
   int GetRemoteInfo(std::string &ip,int &port);
   int GetLocalInfo(std::string &ip,int &port);
   std::string GetSessionId();
   std::string remoteIp;
   int remotePort;
   int localPort;
   int connectTimeOut;
protected:
   enum SocketStatus
   {
      CONNECTED,
      DISCONNECTED
   };

   SocketStatus m_eStatus;
   Socket m_ConnectSocket; // ConnectSocket
   //unsigned m_uRetryCount;
   //unsigned m_uRetryPeriod;
#ifndef WINDOWS
   struct addrinfo* m_pResultAddrInfo = nullptr;
   struct addrinfo  m_HintsAddrInfo;
   bool tryFreeAddrinfo(addrinfo* addr_info);
   bool checkAddrinfo(addrinfo* addr_info);
#else
   void setSocketBlock(unsigned long long  sck, bool bBlock);

#endif // !WINDOWS

private:
   void overlook_SIGPIPE();
   int checkIsConnected();
   void changeSocketStat();
   
};

#endif
