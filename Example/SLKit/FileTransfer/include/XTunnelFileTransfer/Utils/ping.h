#ifdef _WIN32
#include <WinSock2.h>
#pragma comment(lib, "WS2_32")

struct WindowsSocketLibInit
{
    WindowsSocketLibInit()
    {
        WSADATA wsaData;
        WORD sockVersion = MAKEWORD(2, 2);
        WSAStartup(sockVersion, &wsaData);
    }
    ~WindowsSocketLibInit()
    {
        WSACleanup();
    }
} INITSOCKETGLOBALVARIABLE;
#else
#include <unistd.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#endif
#include <stdio.h>
#include <string>
#include <limits>

bool Ping(std::string ip)
{
    static unsigned INDEX = 0;

    const unsigned IP_HEADER_LENGTH = 20;
    const unsigned FILL_LENGTH = 32;

    struct IcmpHdr
    {
        unsigned char icmpType;
        unsigned char icmpCode;
        unsigned short icmpChecksum;

        unsigned short icmpId;
        unsigned short icmpSequence;
    };

    int socketFd = socket(AF_INET, SOCK_RAW, IPPROTO_ICMP);

    int timeoutTick = 1000;
    setsockopt(socketFd, SOL_SOCKET, SO_RCVTIMEO, (char *)&timeoutTick, sizeof(timeoutTick));

    sockaddr_in des = { AF_INET, htons(0) };
    des.sin_addr.s_addr = inet_addr(ip.c_str());

    char buff[sizeof(IcmpHdr) + 32] = { 0 };
    IcmpHdr *pIcmpHdr = (IcmpHdr *)(buff);

    unsigned short id = std::rand() % (std::numeric_limits<unsigned short>::max)();

    pIcmpHdr->icmpType = 8;
    pIcmpHdr->icmpCode = 0;
    pIcmpHdr->icmpId = id;
    pIcmpHdr->icmpSequence = INDEX++;
    memcpy(&buff[sizeof(IcmpHdr)], "FlushHip", sizeof("FlushHip"));
    pIcmpHdr->icmpChecksum = [](unsigned short *buff, unsigned size) -> unsigned short
    {
        unsigned long ret = 0;

        for (unsigned i = 0; i < size; i += sizeof(unsigned short), ret += *buff++) {}

        if (size & 1) ret += *(unsigned char *)buff;

        ret = (ret >> 16) + (ret & 0xFFFF);
        ret += ret >> 16;

        return (unsigned short)~ret;
    }((unsigned short *)buff, sizeof(buff));

    if (-1 == sendto(socketFd, buff, sizeof(buff), 0, (sockaddr *)&des, sizeof(des)))
        return false;

    char recv[1 << 10];
    int ret = recvfrom(socketFd, recv, sizeof(recv), 0, NULL, NULL);
    if (-1 == ret || ret < 20 + sizeof(IcmpHdr))
        return false;

    IcmpHdr *pRecv = (IcmpHdr *)(recv + 20);
    return !(pRecv->icmpType != 0 || pRecv->icmpId != id);
}
