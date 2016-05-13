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
{
    AVCaptureVideoPreviewLayer *_videoPreviewLayer;
    AVCaptureSession *_session;
}

//+ (Class)layerClass
//{
//    return [AVCaptureVideoPreviewLayer class];
//}

- (void)setSession:(AVCaptureSession *)session
{
    _session = session;
//    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
//    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
//    previewLayer.session = session;
    
    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
    _videoPreviewLayer.frame = self.layer.bounds;
    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    [self.layer addSublayer:_videoPreviewLayer];
    
}

- (AVCaptureSession *)session
{
//    AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.layer;
//    
//    
////    self.contentMode = UIViewContentModeScaleToFill;
//    
//    return previewLayer.session;
//    
    
//    _videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
//    //设置layer大小
//    _videoPreviewLayer.frame = view.layer.bounds;
//    //layer填充状态
//    _videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
//    
    return _session;
}


- (AVCaptureVideoPreviewLayer *)previewLayer
{
    return _videoPreviewLayer;
}
@end