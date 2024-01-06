//
//  SLLocalFileDBModel.h
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/18.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "SLFileModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,SLLocalFileDBModelType) {
    dbSend = 0, //未知
    dbReceive = 1,
};

@interface SLLocalFileDBModel : RLMObject

@property (nonatomic,copy) NSString *path;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *extensionName;
@property (nonatomic,assign) long long time;
@property (nonatomic,assign) int type;

+ (SLLocalFileDBModel *)modelWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName time:(long long)time type:(SLLocalFileDBModelType)type;
- (SLFileModel *)toFile;
@end

NS_ASSUME_NONNULL_END
