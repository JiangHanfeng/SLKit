//
//  NSString+Transition.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/6.
//

#import "NSString+Transition.h"
#import "tools.h"

@implementation NSString (Transition)

- (std::wstring)toWString{
    const char *cString = [self cStringUsingEncoding:NSUTF8StringEncoding];
    return t_to_wstring(cString);
}

+ (NSString *)stringWithWString:(std::wstring)wString {
    std::string string = t_to_string(wString);
    return  [NSString stringWithCString:string.c_str() encoding:NSUTF8StringEncoding];
}

@end
