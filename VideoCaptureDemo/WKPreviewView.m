//
//  WKPreviewView.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/9.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "WKPreviewView.h"
#import <AVFoundation/AVFoundation.h>

@implementation WKPreviewView

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (void)setSession:(AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    previewLayer.session = session;
}

- (AVCaptureSession *)session
{
    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
    
    return previewLayer.session;
}

@end
