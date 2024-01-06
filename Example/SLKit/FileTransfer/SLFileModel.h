//
//  SLFileModel.h
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger,SLFileType) {
    unknownFileType = 0,
    folderFileType= 1,
    videoFileType= 2,
    imageFileType = 3,
    audioFileType = 4,
    excelFileType = 5,
    pdfFileType = 6,
    wordFileType = 7,
    pptFileType = 8,
    zipFileType = 9,
    txtFileType = 10,
};

@interface SLFileModel : NSObject
@property (nonatomic,copy) NSString *path;
@property (nonatomic,copy) NSString *name;
@property (nonatomic,copy) NSString *extensionName;
@property (nonatomic,assign) long long time;

- (NSString *)fullPath;

- (SLFileType)fileType;

- (NSString *)fullFileNama;

@end

NS_ASSUME_NONNULL_END
