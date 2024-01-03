//
//  NSString+Transition.h
//  Test-OC
//
//  Created by shenjianfei on 2023/6/6.
//

#import <Foundation/Foundation.h>
#import "string"

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Transition)

- (std::wstring)toWString;
+ (NSString *)stringWithWString:(std::wstring)wString;

@end

NS_ASSUME_NONNULL_END
