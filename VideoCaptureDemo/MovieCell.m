//
//  MovieCell.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "MovieCell.h"
#import <AVFoundation/AVFoundation.h>
#import "WKVideoConverter.h"
#import "WKProgressView.h"

const CGFloat WKProgressRadius = 30.f;

@interface MovieCell ()

<
WKVideoConverterDelegate
>

@end

@implementation MovieCell
{
    __weak IBOutlet UIImageView *_previewImageView;
    AVPlayer *_player;
    AVPlayerLayer *_playLayer;
    UIView *_preView;
    WKVideoConverter *_converter;
    NSURL *_url;
    
//    CAShapeLayer *_progressLayer;
    
    WKProgressView *_progressView;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
    
    

    _progressView = [[WKProgressView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    _progressView.center = CGPointMake(CGRectGetWidth(_previewImageView.frame) / 2, CGRectGetHeight(_previewImageView.frame) / 2);
     [self->_previewImageView addSubview:_progressView];

    _progressView.borderColor = [UIColor grayColor];
    _progressView.progressColor = [UIColor whiteColor];
    _progressView.progress = .7;
    _progressView.progressWidth = 10;
    
//    _progressLayer = [[CAShapeLayer alloc] init];
//    [self.contentView.layer addSublayer:_progressLayer];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupWithMovieUrl:(NSURL *)url
{
    _url = url;

    _converter = [[WKVideoConverter alloc] init];
    
    __weak typeof(self)weakSelf = self;
    
    [_converter convertVideoFirstFrameWithURL:_url finishBlock:^(id result) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            
            strongSelf->_previewImageView.image = result;
        });
    }];
    
    _converter.delegate = self;
}


- (void)showAnimatedImages
{
    __weak typeof(self)weakSelf = self;
    [_converter convertVideoToImagesWithURL:_url
                                finishBlock:^(NSArray *images) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:_url options:nil];
                                    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
                                    // asset.duration.value/asset.duration.timescale 得到视频的真实时间
                                    animation.duration = asset.duration.value/asset.duration.timescale;
                                    animation.values = images;
                                    animation.repeatCount = MAXFLOAT;
                                    [strongSelf->_previewImageView.layer addAnimation:animation forKey:nil];
                                    // 确保内存能及时释放掉
                                    [images enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        if (obj) {
                                            //                                            NSLog(@"%@", obj);
                                            obj = nil;
                                            
                                            //            CGImageRelease((__bridge CGImageRef)obj);
                                        }
                                    }];
                                    //                           images = nil;
//                                    _converter = nil;
                                }];
}


- (void)videoConverter:(WKVideoConverter *)converter progress:(CGFloat)progress
{
    _progressView.progress = progress;
    
    if (fmodf(progress, 1.f) == 0.f) {
        
        _progressView.hidden = YES;
        
    }else{
        if (progress <= 1.0) {
            _progressView.hidden = NO;
        }
        
    }
    
}

- (void)videoConverterFinishConvert:(WKVideoConverter *)converter
{
    
}

- (void)prepareForReuse
{
    [_previewImageView.layer removeAllAnimations];
    
}

- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
