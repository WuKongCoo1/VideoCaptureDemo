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

@implementation MovieCell
{
    AVPlayer *_player;
    AVPlayerLayer *_playLayer;
    UIView *_preView;
    WKVideoConverter *_converter;
}
- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setupWithMovieUrl:(NSURL *)url
{
//    [_playLayer removeFromSuperlayer];
//    
//    AVPlayer *player = [[AVPlayer alloc] initWithURL: url]; // Create The AVPlayer With the URL
//    _playLayer = [AVPlayerLayer playerLayerWithPlayer: player];//Place it to A Layer
//    _playLayer.frame = self.contentView.frame;//Create A view frame size to match the view
//    [self.contentView.layer addSublayer: _playLayer];//Add it to Player Layer
//    [_playLayer setNeedsDisplay];// Set it to Display
//    [player play];//Play it
//    _player = player;
    
    _preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    _preView.center = self.contentView.center;
    [self.contentView addSubview:_preView];
    
    
//    /Users/wukong/Desktop/0.MOV
    _converter = [[WKVideoConverter alloc] init];
    
    __weak typeof(self)weakSelf = self;
    
    
    [_converter convertVideoToImagesWithURL:url
                                finishBlock:^(NSArray *images) {
                                    __strong typeof(weakSelf) strongSelf = weakSelf;
                                    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
                                    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
                                    // asset.duration.value/asset.duration.timescale 得到视频的真实时间
                                    animation.duration = asset.duration.value/asset.duration.timescale;
                                    animation.values = images;
                                    animation.repeatCount = MAXFLOAT;
                                    [strongSelf->_preView.layer addAnimation:animation forKey:nil];
                                    // 确保内存能及时释放掉
                                    [images enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        if (obj) {
//                                            NSLog(@"%@", obj);
                                            obj = nil;
                                            
                                            //            CGImageRelease((__bridge CGImageRef)obj);
                                        }
                                    }];
                                    //                           images = nil;
                                    _converter = nil;
                                }];
}


- (void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
