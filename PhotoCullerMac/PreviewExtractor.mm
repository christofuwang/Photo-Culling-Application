#import "PreviewExtractor.h"
#include <libraw.h>

@implementation PreviewExtractor

// ------------------
// Thumbnail Extraction
// ------------------
+ (NSData *)extractThumbnailAtPath:(NSString *)path
{
    LibRaw raw;

    if (raw.open_file([path fileSystemRepresentation]) != LIBRAW_SUCCESS)
        return nil;

    if (raw.unpack_thumb() != LIBRAW_SUCCESS) {
        raw.recycle();
        return nil;
    }

    libraw_processed_image_t *thumb = raw.dcraw_make_mem_thumb();
    if (!thumb || thumb->type != LIBRAW_IMAGE_JPEG) {
        raw.recycle();
        return nil;
    }

    NSData *data = [NSData dataWithBytes:thumb->data
                                   length:thumb->data_size];

    LibRaw::dcraw_clear_mem(thumb);
    raw.recycle();

    return data;
}

// ------------------
// Full Raw Extraction
// ------------------
+ (NSData *)extractFullImageAtPath:(NSString *)path
                             width:(int *)outWidth
                            height:(int *)outHeight
                          channels:(int *)outChannels
{
    LibRaw raw;

    if (raw.open_file([path fileSystemRepresentation]) != LIBRAW_SUCCESS)
        return nil;

    if (raw.unpack() != LIBRAW_SUCCESS) {
        raw.recycle();
        return nil;
    }

    if (raw.dcraw_process() != LIBRAW_SUCCESS) {
        raw.recycle();
        return nil;
    }
    
    libraw_processed_image_t *img = raw.dcraw_make_mem_image();
    if (!img) {
        raw.recycle();
        return nil;
    }

    int width = img->width;
    int height = img->height;
    int channels = img->colors; // usually 3

    if (outWidth) *outWidth = width;
    if (outHeight) *outHeight = height;
    if (outChannels) *outChannels = channels;

    NSData *data = [NSData dataWithBytes:img->data
                                   length:img->data_size];

    LibRaw::dcraw_clear_mem(img);
    return data;
}

@end

