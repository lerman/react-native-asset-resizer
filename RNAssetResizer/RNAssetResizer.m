//
//  Created by Jeff Lerman Oct 5, 2016
//

#import "RNAssetResizer.h"

#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
@import Photos;

@implementation RNAssetResizer

-(UIImage *)resizeImage :(UIImage *)theImage :(CGSize)theNewSize {
    UIGraphicsBeginImageContextWithOptions(theNewSize, NO, 1.0);
    [theImage drawInRect:CGRectMake(0, 0, theNewSize.width, theNewSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

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
         // grab metadata and add originalUri to EXIF
         NSDictionary *metadata = [self metadataFromImageData:imageData];
         NSMutableDictionary *mutableMetadata = nil;

         if (metadata != nil) {
             mutableMetadata = [metadata mutableCopy];
             NSArray *resources = [PHAssetResource assetResourcesForAsset:_asset];
             NSString *orgFilename = ((PHAssetResource*)resources[0]).originalFilename;
             [mutableMetadata setValue:orgFilename forKey:@"originalUri"];
         }


         UIImage *newImage = [UIImage imageWithData:imageData];


         // TODO FIXME: change this to figure out based on max width/height scale
         UIImage *scaledImage = [self resizeImage:newImage :newSize];

         NSLog(@"Got newImage w[%f] h[%f] s[%f] thisO[%ld], origO[%ld]", newImage.size.width, newImage.size.height, newImage.scale, (long)newImage.imageOrientation,(long)orientation);

         NSLog(@"Got scaledImage w[%f] h[%f] s[%f] thisO[%ld], origO[%ld]", scaledImage.size.width, scaledImage.size.height, scaledImage.scale, (long)scaledImage.imageOrientation,(long)orientation);

         // set the quality
         [mutableMetadata setObject:@(.75) forKey:(__bridge NSString *)kCGImageDestinationLossyCompressionQuality];

         NSLog(@"Hi");
         NSLog( @"%@", mutableMetadata );

         // Create an image destination.
         CGImageDestinationRef imageDestination = CGImageDestinationCreateWithURL((__bridge CFURLRef)[NSURL fileURLWithPath:fullPath], kUTTypeJPEG , 1, NULL);

         if (imageDestination == NULL ) {
             // Handle failure.
             NSLog(@"Error -> failed to create image destination.");
             reject(@"Error", nil, nil);
         }

         // Add your image to the destination.
         CGImageDestinationAddImage(imageDestination, scaledImage.CGImage, (__bridge CFDictionaryRef)mutableMetadata);

         BOOL finalized = CGImageDestinationFinalize(imageDestination);

         // Finalize the destination.
         if (finalized == NO) {
             // Handle failure.
             NSLog(@"Error -> failed to finalize the image.");
         }

         CFRelease(imageDestination);

         if(finalized) {
             resolve(fullPath);
         } else {
             reject(@"Error", nil, nil);
         }
     }];
}

@end
