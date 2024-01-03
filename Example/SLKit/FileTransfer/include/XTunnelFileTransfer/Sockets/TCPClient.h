/*
* @file TCPClient.h
* @brief wrapper for TCP client
*
* @author Mohamed Amine Mzoughi <mohamed-amine.mzoughi@laposte.net>
* @date 2013-05-11
*/

#ifndef INCLUDE_TCPCLIENT_H_
#define INCLUDE_TCPCLIENT_H_

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
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#endif

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

   // Setters - Getters (for unit tests)
   /*inline*/// void SetProgressFnCallback(void* pOwner, const ProgressFnCallback& fnCallback);
   /*inline*/// void SetProxy(const std::string& strProxy);
   /*inline auto GetProgressFnCallback() const
   {
      return m_fnProgressCallback.target<int(*)(void*, double, double, double, double)>();
   }
   inline void* GetProgressFnCallbackOwner() const { return m_ProgressStruct.pOwner; }*/
   //inline const std::string& GetProxy() const { return m_strProxy; }
   //inline const unsigned char GetSettingsFlags() const { return m_eSettingsFlags; }

	// Session
   bool Connect(const std::string& strServer, const std::string& strPort); // connect to a TCP server
   bool SetSocket(Socket connectSocket,const std::string& strServer, const std::string& strPort);
   bool Disconnect(); // disconnect from the TCP server
   bool Send(const char* pData, const size_t uSize) ; // send data to a TCP server
   bool Send(const std::string& strData) ;
   bool Send(const std::vector<char>& Data) ;
   int  Receive(char* pData, const size_t uSize, bool bReadFully = true) ;

   // To disable timeout, set msec_timeout to 0.
   bool SetRcvTimeout(unsigned int msec_timeout);
   bool SetSndTimeout(unsigned int msec_timeout);
   bool GetRomoteIPAndPort(std::string remoteIp,int &port);
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

   struct addrinfo* m_pResultAddrInfo;
   struct addrinfo  m_HintsAddrInfo;
private:
   void overlook_SIGPIPE();
   int checkIsConnected();
   void changeSocketStat();
};

#endif
