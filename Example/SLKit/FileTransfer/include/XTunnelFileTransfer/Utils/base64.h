//
//  base64.h
//  CPPWork
//  from http://stackoverflow.com/questions/180947/base64-decode-snippet-in-c
//  Created by cocoa on 16/8/5.
//  Copyright © 2016年 cc. All rights reserved.
//
#ifndef _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#define _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING
#endif // silence codecvt warnings
#ifndef base64_h
#define base64_h

#include <string>

//string <=>wstring
#include <string>
#include <codecvt>
#include <locale>
using convert_t = std::codecvt_utf8<wchar_t>;


std::string base64_encode( char const* bytes_to_encode, unsigned int in_len);
std::string base64_decode(std::string const& encoded_string);
std::string string_encode(std::wstring bytes_to_encode);
std::wstring string_decode(std::string const& encoded_string);
#ifdef WINDOWS
std::string GbkToUtf8(const char *src_str);
std::string Utf8ToGbk(const char *src_str);
#endif
#endif /* base64_h */