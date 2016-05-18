//
//  WKMovieRecorder.h
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/12.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class WKMovieRecorder;

@protocol WKMovieRecorderDelegate <NSObject>

- (void)movieRecorderDidFinishRecording:(WKMovieRecorder *)recorder;

@end

@interface WKMovieRecorder : NSObject

@property (nonatomic, weak) id<WKMovieRecorderDelegate> delegate;

- (instancetype)initWithURL:(NSURL *)URL;

- (instancetype)initWithURL:(NSURL *)URL cropSize:(CGSize)cropSize;

- (void)setCropSize:(CGSize)size;

- (void)prepareRecording;

- (void)finishRecording;

- (void)appendAudioBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)appendVideoBuffer:(CMSampleBufferRef)sampleBuffer;

@end
