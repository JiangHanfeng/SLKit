//
//  SLLocalFileDBModel.m
//  FreeStyle
//
//  Created by shenjianfei on 2023/7/18.
//

#import "SLLocalFileDBModel.h"

@implementation SLLocalFileDBModel

+(SLLocalFileDBModel *)modelWithPath:(NSString *)path name:(NSString *)name extensionName:(NSString *)extensionName time:(long long)time type:(SLLocalFileDBModelType)type {
    SLLocalFileDBModel *model = [[SLLocalFileDBModel alloc] init];
    model.path = path;
    model.name = name;
    model.extensionName = extensionName;
    model.time = time;
    model.type = (int)type;
    return  model;
}

- (SLFileModel *)toFile {
    SLFileModel *model =  [[SLFileModel alloc] init];
    model.path = self.path;
    model.name = self.name;
    model.extensionName = self.extensionName;
    model.time = self.time;
    return  model;
}

@end
