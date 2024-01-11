// #ifndef WINDOWS
// #define WINDOWS
// #endif
#ifndef _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#endif // silence codecvt warnings
#ifndef INCLUDE_TOOLS_H_
#define INCLUDE_TOOLS_H_

#include <string>
#include <vector>
#include <list>
#include <time.h>
#include <ctime> 
#include <sys/stat.h>//使用stat函数获取文件状态，成功则存在，否则不存在
#include <ostream>
#include <string.h>
#include <iostream>
#include <sstream>
#include <iomanip>
#include <chrono>
#include <functional>
#include <random>
#include <filesystem>//文件操作相关
#include "MD5.h"
//string <=>wstring
#include <string>
#include <codecvt>
#include <locale>

#ifdef WINDOWS
#include <io.h>
#include <windows.h>
#include <direct.h>
#else
#include <unistd.h>
#include <dirent.h>//是POSIX.1标准定义的unix类目录操作的头文件，包含了许多UNIX系统服务的函数原型，例如opendir()函数、readdir()函数
#include <sys/types.h>
#define _stat64 stat
#endif
//using namespace std;
#define EndFlag_linux  L"/";
#define EndFlag_win  L"\\";

#define rate_kb 1024
#define rate_mb 1024*1024

struct filePathInfo
{
    std::wstring basePath;//基路径：C:\Users\11320
    std::wstring relativePath;//相对路径：Music
    std::wstring fileName;//文件名称：04 Thinkvision_Lenovo演示视频.mp4
    std::wstring fullPath;//基路径+相对路径+文件名称
};
#include <functional>

using convert_t = std::codecvt_utf8<wchar_t>;


static long long uuidCount=0;
int myAdd(int a,int b);
int GetRandom();
std::string GetTimeString();
std::string GetTimeString(time_t timep);
std::string GetTimeGuid();
std::string CreateUuid();
bool fileExists (const std::wstring& path);
long long getFileSize (const std::wstring& path);
// long GetFileSize2(const string filepath);
// LPCWSTR stringToLPCWSTR(std::string orig);
std::vector<std::wstring> testSplit(std::wstring srcStr, const std::wstring& flag);
std::vector<std::wstring> testSplit(std::wstring srcStr, const std::wstring& flag1, const std::wstring& flag2);
int FindFirstFlag(const char* buffer,int dataLength,const char*endFlag,int endFlagLength);
int trimLeft(char* buffer,int dataLength,int trimLength);
int strCopy(char* strDest,const char* strSource,int sourceBegin,int sourceLength);
std::wstring GetParentFolderPath(std::wstring path);
std::wstring GetLastFolderName(std::wstring path);
std::wstring GetFileName(std::wstring path);
std::wstring GetFileNameNoExtend(std::wstring filePath);
std::wstring GetFileNameExtend(std::wstring filePath);
/// <summary>
/// 路径是否是一个文件夹
/// </summary>
/// <param name="path">路径</param>
/// <returns>-1路径不存在，0是文件，1是文件夹</returns>
int IsFolder(std::wstring path);
std::wstring TrimStr(std::wstring str,const std::wstring &flag,bool trimLeft=false);
std::wstring Combine(std::wstring path1,std::wstring path2,bool appendEndTag=false);
std::wstring Combine(std::wstring path1,std::wstring path2,std::wstring path3,bool appendEndTag=false);
long GetMinBufferSize(long size1,long size2,long minSize);
void log(std::wstring msg);
//void Delay(int  time);
std::list<filePathInfo> getAllFiles(std::wstring basePath, std::wstring relativePath,bool depth=true);
int mkpath(std::wstring s);
int mkfile(std::wstring s);
void SleepSecond(int second);
void SleepMillisecond(int millisecond);
#define enum_to_string(x) #x

std::string GetHash(std::wstring filePath);
/// @brief 快速hash 以分段的形式获取hash，以达到加快hash计算速度的需要
/// @param filePath 
/// @param model 
/// @return 
std::string GetFastHash(std::wstring filePath,int model=0);
int RemoveFile(std::wstring filePath);
int ReNameFile(std::wstring oldName, std::wstring NewName);

std::string GetRateString(long long rate=0);

std::string t_to_string(std::wstring wstr);
std::wstring t_to_wstring(std::string str);
std::wstring GetPtrString(void* ptr);

std::wstring replaceString(std::wstring str, std::wstring oldStr, std::wstring newStr);
#ifdef ANDROID
void ChangeMode(std::wstring tPath, std::filesystem::perms mode);
#endif // ANDROID
std::wstring getRelativePath(std::wstring _path, std::wstring pathRoot);
#endif