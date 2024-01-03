#ifndef JSONHELPER_H
#define JSONHELPER_H
#include <string>
// #include <jsoncpp/json/json.h>
#include "../jsoncpp/json/json.h"
#include "FileTransferModel.h"
using namespace Json;
std::string ToJson(FileTransferRequestInfo model);
int LoadJson(std::string json,FileTransferRequestInfo &model);

std::string ToJson(ControlMsg model);
int LoadJson(std::string json,ControlMsg &model);

std::string ToJson(FileTransferResponseInfo model);
int LoadJson(std::string json,FileTransferResponseInfo &model);

std::string ToJson(TransferFileControlRequest model);
int LoadJson(std::string json,TransferFileControlRequest &model);

std::string ToJson(FileTransferError model);
int LoadJson(std::string json, FileTransferError& model);

std::string ToJson(FileTransferProgress model);
int LoadJson(std::string json, FileTransferProgress& model);

std::string ToJson(FileTransferState model);
int LoadJson(std::string json, FileTransferState& model);

std::string ToJson(FileTransferTask model);
int LoadJson(std::string json, FileTransferTask& model);

std::string ToJson(LineMsgInfo model);
int LoadJson(std::string json, LineMsgInfo& model);
#endif