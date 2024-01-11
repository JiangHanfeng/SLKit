#pragma once
#ifndef ReceiveFileInfoUnit_H
#define ReceiveFileInfoUnit_H
#include <string>
#include <list>
#include "../Utils/SimperSafeMap.h"
#include <mutex>
#include "FileTransferModel.h"
class ReceiveFileInfoUnit
{
public:

	SimperSafeMap<std::wstring, TransferFileInfo> taskFileInfoList;


	ReceiveFileInfoUnit();
	//ReceiveFileInfoUnit(const ReceiveFileInfoUnit&);   //拷贝构造函数不实现，防止拷贝产生多个实例
	static  ReceiveFileInfoUnit* GetInstance();
	bool HasRepeatFile(TransferFileInfo &fileInfo);
	/// <summary>
	/// 获取一个可用的文件名称，并缓存此信息
	/// </summary>
	/// <param name="fileInfo"></param>
	/// <returns></returns>
	std::wstring GetFileSaveNameAndCache(std::wstring taskId, TransferFileInfo fileInfo);
	std::list<TransferFileInfo> GetFileSaveNameAndCache(std::wstring taskId, std::list<TransferFileInfo> &fileInfoList);
	void removeFileInfoCache(std::wstring taskId);
	std::mutex mtx_;

private:
};



#endif

