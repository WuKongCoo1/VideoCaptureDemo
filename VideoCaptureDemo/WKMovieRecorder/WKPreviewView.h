//
//  WKPreviewView.h
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/9.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import <UIKit/UIKit.h>
@class AVCaptureVideoPreviewLayer;
@class AVCaptureSession;

@interface WKPreviewView : UIView

@property (nonatomic) AVCaptureSession *session;

@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

@end
