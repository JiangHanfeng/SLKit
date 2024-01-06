//
//  SLFileModel.m
//  Test-OC
//
//  Created by shenjianfei on 2023/6/8.
//

#import "SLFileModel.h"

@implementation SLFileModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.path = @"/";
        self.name = @"";
        self.extensionName = @"";
    }
    return self;
}

- (NSString *)fullFileNama{
    return [NSString stringWithFormat:@"%@.%@",self.name,self.extensionName];
}

- (NSString *)fullPath {
    return [NSString stringWithFormat:@"%@%@.%@",self.path,self.name,self.extensionName];
}

- (SLFileType)fileType {

    if (self.extensionName == nil) {
        return unknownFileType;
    }

    NSString *extensionType = [self.extensionName lowercaseString];
    
    if(extensionType.length == 0){
        return folderFileType;
    } else if([extensionType hasSuffix:@"avi"]||[extensionType hasSuffix:@"rmvb"] || [extensionType hasSuffix:@"rm"] ||
              [extensionType hasSuffix:@"asf"]||[extensionType hasSuffix:@"divx"] || [extensionType hasSuffix:@"mpg"] ||
              [extensionType hasSuffix:@"mpeg"]||[extensionType hasSuffix:@"mpe"] || [extensionType hasSuffix:@"wmv"] ||
              [extensionType hasSuffix:@"mp4"]||[extensionType hasSuffix:@"mkv"] || [extensionType hasSuffix:@"vob"] ||
              [extensionType hasSuffix:@"mov"]){
        return videoFileType;
    } else if([extensionType hasSuffix:@"pcx"]||[extensionType hasSuffix:@"emf"] || [extensionType hasSuffix:@"gif"] ||
              [extensionType hasSuffix:@"bmp"]||[extensionType hasSuffix:@"tga"] || [extensionType hasSuffix:@"jpg"] ||
              [extensionType hasSuffix:@"tif"]||[extensionType hasSuffix:@"jpeg"] || [extensionType hasSuffix:@"png"] ||
              [extensionType hasSuffix:@"rle"]){
        return imageFileType;
    } else if([extensionType hasSuffix:@"mp3"]||[extensionType hasSuffix:@"ogg"] || [extensionType hasSuffix:@"wav"] ||
              [extensionType hasSuffix:@"ape"]||[extensionType hasSuffix:@"cda"] || [extensionType hasSuffix:@"au"] ||
              [extensionType hasSuffix:@"midi"]||[extensionType hasSuffix:@"mac"] || [extensionType hasSuffix:@"aac"] ||
              [extensionType hasSuffix:@"flac"]){
        return audioFileType;
    } else if([extensionType hasSuffix:@"excel"]||[extensionType hasSuffix:@"xls"]||[extensionType hasSuffix:@"xlsx"]){
        return excelFileType;
    } else if ([extensionType hasSuffix:@"pdf"]) {
        return pdfFileType;
    } else if ([extensionType hasSuffix:@"doc"]||[extensionType hasSuffix:@"docx"]) {
        return wordFileType;
    } else if ([extensionType hasSuffix:@"pptx"] || [extensionType hasSuffix:@"ppt"]) {
        return pptFileType;
    } else if ([extensionType hasSuffix:@"zip"] || [extensionType hasSuffix:@"rar"] ||
               [extensionType hasSuffix:@"7z"] || [extensionType hasSuffix:@"tar"] ||
               [extensionType hasSuffix:@"gz"] || [extensionType hasSuffix:@"bz"]) {
        return zipFileType;
    } else if ([extensionType hasSuffix:@"txt"] || [extensionType hasSuffix:@"log"] || [extensionType hasSuffix:@"text"]) {
        return txtFileType;
    }
    return unknownFileType;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"path = %@ name = %@ extensionName = %@ fullPath = %@ type = %ld",self.path,self.name,self.extensionName,[self fullPath],(long)[self fileType]];
}

@end
