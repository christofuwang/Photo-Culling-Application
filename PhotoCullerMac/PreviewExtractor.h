#import <Foundation/Foundation.h>

@interface PreviewExtractor : NSObject

// Fast thumbnail (small, JPEG)
+ (NSData *)extractThumbnailAtPath:(NSString *)path;

// Full raw image (RGB), returns data + width/height/channels
+ (NSData *)extractFullImageAtPath:(NSString *)path
                             width:(int *)outWidth
                            height:(int *)outHeight
                          channels:(int *)outChannels;

@end
