//
//  Created by Jeff Lerman Oct 5, 2016
//

#import "RNAssetResizer.h"
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAsset.h>
@import Photos;

@implementation RNAssetResizer


-(NSDictionary*)metadataFromImageData:(NSData*)imageData{
    CGImageSourceRef imageSource = CGImageSourceCreateWithData((__bridge CFDataRef)(imageData), NULL);
    if (imageSource) {
        NSDictionary *options = @{(NSString *)kCGImageSourceShouldCache : [NSNumber numberWithBool:NO]};
        CFDictionaryRef imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, (__bridge CFDictionaryRef)options);
        if (imageProperties) {
            NSDictionary *metadata = (__bridge NSDictionary *)imageProperties;
            CFRelease(imageProperties);
            CFRelease(imageSource);
            NSLog(@"Metadata of selected image%@",metadata);// It will display the metadata of image after converting NSData into NSDictionary
            return metadata;
            
        }
        CFRelease(imageSource);
    }
    
    NSLog(@"Can't read metadata");
    return nil;
}

- (UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

/*
bool saveImage(NSString * fullPath, UIImage * image, NSString * format, float quality)
{
    NSData* data = nil;
    if ([format isEqualToString:@"JPEG"]) {
        data = UIImageJPEGRepresentation(image, quality / 100.0);
    } else if ([format isEqualToString:@"PNG"]) {
        data = UIImagePNGRepresentation(image);
    }
    
    if (data == nil) {
        return NO;
    }
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    [fileManager createFileAtPath:fullPath contents:data attributes:nil];
    return YES;
}
 */

- (NSString *)generateFilePath:(NSString *)outputPath ext:(NSString *)ext
{
    NSString* directory;
    
    if ([outputPath length] == 0) {
        NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
        directory = [paths firstObject];
    } else {
        directory = outputPath;
    }
    
    NSString* name = [[NSUUID UUID] UUIDString];
    NSString* fullName = [NSString stringWithFormat:@"%@.%@", name, ext];
    NSString* fullPath = [directory stringByAppendingPathComponent:fullName];
    
    return fullPath;
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(resizeAsset:(NSURL *)assetPath
                  width:(float)width
                  height:(float)height
                  outputPath:(NSString *)outputPath
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject)
{

    CGSize newSize = CGSizeMake(width, height);
    NSString* fullPath = [self generateFilePath:outputPath ext:@"jpg"];
    PHAsset *_asset = [[PHAsset fetchAssetsWithALAssetURLs:@[assetPath] options:nil] firstObject];

    if (!_asset) {
        reject(@"Error", nil, nil);
    }
    
    // get photo info from this asset
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    
    requestOptions.synchronous = YES;
    
    [[PHImageManager defaultManager]
     requestImageDataForAsset:_asset
     options:requestOptions
     resultHandler:^(NSData *imageData, NSString *dataUTI,
                     UIImageOrientation orientation,
                     NSDictionary *info)
     {
         NSDictionary *metadata = [self metadataFromImageData:imageData];
         NSDictionary *mutableMetadata = nil;

         if (metadata != nil) {
             mutableMetadata = [metadata mutableCopy];
             NSArray *resources = [PHAssetResource assetResourcesForAsset:_asset];
             NSString *orgFilename = ((PHAssetResource*)resources[0]).originalFilename;
             [mutableMetadata setValue:orgFilename forKey:@"originalUri"];
         }

         NSLog(@"Hi");
         NSLog( @"%@", mutableMetadata );

         if(true) {
             resolve(fullPath);
         } else {
             reject(@"Error", nil, nil);
         }
     }];
}

@end
