//
//  WKVideoConverter.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "WKVideoConverter.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, WKConvertType) {
    WKConvertTypeImage,
    WKConvertTypeImages
};

typedef id (^HandleBlcok)(AVAssetReaderTrackOutput *outPut, AVAssetTrack *videoTrack);

@interface WKVideoConverter ()

@property (nonatomic, strong) AVAssetReader *reader;

@end

@implementation WKVideoConverter

+ (void)shareInstance
{
    static WKVideoConverter *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (instance == nil) {
            instance = [WKVideoConverter new];
        }
    });
    
}

- (void)convertVideoToImagesWithURL:(NSURL *)url finishBlock:(void (^)(id))finishBlock
{
    
    [self convertVideoFirstFrameWithURL:url type:WKConvertTypeImages finishBlock:finishBlock];
//    AVAsset *asset = [AVAsset assetWithURL:url];
//    NSError *error = nil;
//    self.reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
//    __weak typeof(self)weakSelf = self;
//    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//    dispatch_async(backgroundQueue, ^{
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        NSLog(@"");
//        
//        
//        if (error) {
//            NSLog(@"%@", [error localizedDescription]);
//
//        }
//        
//        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
//        
//        AVAssetTrack *videoTrack =[videoTracks firstObject];
//        if (!videoTrack) {
//            return ;
//        }
//        int m_pixelFormatType;
//        //     视频播放时，
//        m_pixelFormatType = kCVPixelFormatType_32BGRA;
//        // 其他用途，如视频压缩
//        //    m_pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
//        
//        NSMutableDictionary *options = [NSMutableDictionary dictionary];
//        [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
//        [strongSelf.reader addOutput:videoReaderOutput];
//        [strongSelf.reader startReading];
//        
//        // 要确保nominalFrameRate>0，之前出现过android拍的0帧视频
//        
//        NSMutableArray *images = [NSMutableArray array];
//        CGFloat seconds = CMTimeGetSeconds(videoTrack.timeRange.duration);
//        CGFloat totalFrame = videoTrack.nominalFrameRate * seconds;
//        NSLog(@"%f", totalFrame);
//        
//        NSInteger convertedCount = 0;
//        while ([strongSelf.reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
//            // 读取 video sample
//            CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
//            
//            CGImageRef cgimage = [WKVideoConverter imageFromSampleBufferRef:videoBuffer];
//            
//            
//            
//            if (!(__bridge id)(cgimage))
//            {
//                break;
//            }
//            
//            [images addObject:((__bridge id)(cgimage))];
//            
//            CGImageRelease(cgimage);
//            if (videoBuffer) {
//                
//                CMSampleBufferInvalidate(videoBuffer);
//                CFRelease(videoBuffer);
//                videoBuffer = NULL;
//            }
//            // 根据需要休眠一段时间；比如上层播放视频时每帧之间是有间隔的,这里的 sampleInternal 我设置为0.001秒
//            [NSThread sleepForTimeInterval:0.001];
//            
//            CGFloat process = ++convertedCount / totalFrame;
//            
//            NSLog(@"process : %f", process);
//            
//            if ([self.delegate respondsToSelector:@selector(videoConverter:process:)]) {
//                [self.delegate videoConverter:self process:process];
//            }
//        }
//        
//        if (finishBlock) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                finishBlock(images);
//            });
//            
//        }
//
//    });
}

- (void)convertVideoFirstFrameWithURL:(NSURL *)url finishBlock:(void (^)(id))finishBlock
{
    [self convertVideoFirstFrameWithURL:url type:WKConvertTypeImage finishBlock:finishBlock];
//    AVAsset *asset = [AVAsset assetWithURL:url];
//    NSError *error = nil;
//    self.reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
//    __weak typeof(self)weakSelf = self;
//    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//    dispatch_async(backgroundQueue, ^{
//        __strong typeof(weakSelf) strongSelf = weakSelf;
//        NSLog(@"");
//        
//        
//        if (error) {
//            NSLog(@"%@", [error localizedDescription]);
//            
//        }
//        
//        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
//        
//        AVAssetTrack *videoTrack =[videoTracks firstObject];
//        if (!videoTrack) {
//            return ;
//        }
//        int m_pixelFormatType;
//        //     视频播放时，
//        m_pixelFormatType = kCVPixelFormatType_32BGRA;
//        // 其他用途，如视频压缩
//        //    m_pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
//        
//        NSMutableDictionary *options = [NSMutableDictionary dictionary];
//        [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
//        [strongSelf.reader addOutput:videoReaderOutput];
//        [strongSelf.reader startReading];
//        
//        
//        UIImage *image;
//        // 要确保nominalFrameRate>0，之前出现过android拍的0帧视频
//        while ([strongSelf.reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
//            // 读取 video sample
//            CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
//            
//            CGImageRef cgimage = [WKVideoConverter imageFromSampleBufferRef:videoBuffer];
//            
//            
//            
//            if (!(__bridge id)(cgimage))
//            {
//                break;
//            }
//            
//            image = [UIImage imageWithCGImage:cgimage];
//            
//            
//            
//            CGImageRelease(cgimage);
//            if (videoBuffer) {
//                
//                CMSampleBufferInvalidate(videoBuffer);
//                CFRelease(videoBuffer);
//                videoBuffer = NULL;
//            }
//            
//            if (image) {
//                break;
//            }
//            
//            
//        
//        }
//        
//        if (finishBlock) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                finishBlock(image);
//            });
//        }
//    });
}

- (void)convertVideoFirstFrameWithURL:(NSURL *)url type:(WKConvertType)type finishBlock:(void (^)(id))finishBlock
{
    AVAsset *asset = [AVAsset assetWithURL:url];
    NSError *error = nil;
    self.reader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    __weak typeof(self)weakSelf = self;
    dispatch_queue_t backgroundQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
    dispatch_async(backgroundQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSLog(@"");
        
        
        if (error) {
            NSLog(@"%@", [error localizedDescription]);
            
        }
        
        NSArray *videoTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        
        AVAssetTrack *videoTrack =[videoTracks firstObject];
        if (!videoTrack) {
            return ;
        }
        int m_pixelFormatType;
        //     视频播放时，
        m_pixelFormatType = kCVPixelFormatType_32BGRA;
        // 其他用途，如视频压缩
        //    m_pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange;
        
        NSMutableDictionary *options = [NSMutableDictionary dictionary];
        [options setObject:@(m_pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey];
        AVAssetReaderTrackOutput *videoReaderOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:options];
        [strongSelf.reader addOutput:videoReaderOutput];
        [strongSelf.reader startReading];
        
        
        HandleBlcok handleBlock = [self handleVideoWithType:type];
        
        id result = handleBlock(videoReaderOutput, videoTrack);
        
        if (finishBlock) {
            dispatch_async(dispatch_get_main_queue(), ^{
                finishBlock(result);
            });
        }
    });
}

- (HandleBlcok)handleVideoWithType:(WKConvertType)type
{
    
    HandleBlcok block;
    
    switch (type) {
        case WKConvertTypeImage: {
            block = ^(AVAssetReaderOutput *videoReaderOutput, AVAssetTrack *videoTrack){
                UIImage *image;
                // 要确保nominalFrameRate>0，之前出现过android拍的0帧视频
                while ([self.reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
                    // 读取 video sample
                    CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
                    
                    CGImageRef cgimage = [WKVideoConverter imageFromSampleBufferRef:videoBuffer];
                    
                    
                    
                    if (!(__bridge id)(cgimage))
                    {
                        break;
                    }
                    
                    image = [UIImage imageWithCGImage:cgimage];
                    
                    
                    
                    CGImageRelease(cgimage);
                    if (videoBuffer) {
                        
                        CMSampleBufferInvalidate(videoBuffer);
                        CFRelease(videoBuffer);
                        videoBuffer = NULL;
                    }
                    
                    if (image) {
                        return image;
                    }
                }
                return [[UIImage alloc] init];
            };

            break;
        }
        case WKConvertTypeImages: {//图片
            
            block = ^(AVAssetReaderOutput *videoReaderOutput, AVAssetTrack *videoTrack){
                NSMutableArray *images = [NSMutableArray array];
                CGFloat seconds = CMTimeGetSeconds(videoTrack.timeRange.duration);
                CGFloat totalFrame = videoTrack.nominalFrameRate * seconds;
                NSLog(@"%f", totalFrame);
                
                NSInteger convertedCount = 0;
                while ([self.reader status] == AVAssetReaderStatusReading && videoTrack.nominalFrameRate > 0) {
                    // 读取 video sample
                    CMSampleBufferRef videoBuffer = [videoReaderOutput copyNextSampleBuffer];
                    
                    CGImageRef cgimage = [WKVideoConverter imageFromSampleBufferRef:videoBuffer];
                    
                    
                    
                    if (!(__bridge id)(cgimage))
                    {
                        break;
                    }
                    
                    [images addObject:((__bridge id)(cgimage))];
                    
                    CGImageRelease(cgimage);
                    if (videoBuffer) {
                        
                        CMSampleBufferInvalidate(videoBuffer);
                        CFRelease(videoBuffer);
                        videoBuffer = NULL;
                    }
                    // 根据需要休眠一段时间；比如上层播放视频时每帧之间是有间隔的,这里的 sampleInternal 我设置为0.001秒
                    [NSThread sleepForTimeInterval:0.001];
                    
                    CGFloat progress = ++convertedCount / totalFrame;
                    
                    NSLog(@"process : %f", progress);
                    
                    if ([self.delegate respondsToSelector:@selector(videoConverter:progress:)]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                        
                                [self.delegate videoConverter:self progress:progress];
                            
                        });
                    }
                    
                    if (fmodf(progress, 1.f) == 0.f) {
                        if ([self.delegate respondsToSelector:@selector(videoConverterFinishConvert:)]) {
                            [self.delegate videoConverterFinishConvert:self];
                        }
                    }
                    
                    
                    if (self.reader.status == AVAssetReaderStatusCompleted) {
                        break;
                    }
                }

                return images;
            };
        }
    }
    
    
    return block;
    
    
}



+ (CGImageRef)imageFromSampleBufferRef:(CMSampleBufferRef)sampleBufferRef
{
    // 为媒体数据设置一个CMSampleBufferRef
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    // 锁定 pixel buffer 的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    // 得到 pixel buffer 的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    // 得到 pixel buffer 的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到 pixel buffer 的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的 RGB 颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphic context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    //根据这个位图 context 中的像素创建一个 Quartz image 对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁 pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    // 释放 context 和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    // 用 Quzetz image 创建一个 UIImage 对象
    // UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放 Quartz image 对象
//        CGImageRelease(quartzImage);
    
    return quartzImage;
    
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
