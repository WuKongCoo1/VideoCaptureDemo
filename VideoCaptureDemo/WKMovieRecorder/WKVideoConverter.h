//
//  WKVideoConverter.h
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class WKVideoConverter;
@protocol WKVideoConverterDelegate <NSObject>

- (void)videoConverter:(WKVideoConverter *)converter progress:(CGFloat)progress;
- (void)videoConverterFinishConvert:(WKVideoConverter *)converter;

@end

typedef void (^block)(void);

@interface WKVideoConverter : NSObject

@property (nonatomic, weak) id<WKVideoConverterDelegate> delegate;

+ (void)shareInstance;

- (void)convertVideoToImagesWithURL:(NSURL *)url finishBlock:(void (^)(id))finishBlock;

- (void)convertVideoFirstFrameWithURL:(NSURL *)url finishBlock:(void (^)(id))finishBlock;

@end
