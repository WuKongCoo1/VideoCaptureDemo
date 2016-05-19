//
//  PlayViewController.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "PlayViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "WKVideoConverter.h"

#define PreViewWithImage 0

@interface PlayViewController ()

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) UIView *preView;

@property (nonatomic, strong) WKVideoConverter *converter;

@end

@implementation PlayViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    
//    _preView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, <#CGFloat width#>, <#CGFloat height#>)];
//    _preView.center = self.view.center;
//    [self.view addSubview:_preView];
    
    NSString *filePath;
    
#if PreViewWithImage
    
#if TARGET_IPHONE_SIMULATOR
    
    filePath = @"/Users/wukong/Desktop/0.MOV";
#else
    
    filePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/output2.mov"];
    
#endif
    
    
    
    _converter = [[WKVideoConverter alloc] init];
    __weak typeof(self)weakSelf = self;
    [_converter convertVideoToImagesWithURL:[NSURL fileURLWithPath:filePath]
                                finishBlock:^(NSArray *images) {
                                    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:filePath] options:nil];
                                    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"contents"];
                                    // asset.duration.value/asset.duration.timescale 得到视频的真实时间
                                    animation.duration = asset.duration.value/asset.duration.timescale;
                                    animation.values = images;
                                    animation.repeatCount = MAXFLOAT;
                                    [weakSelf.preView.layer addAnimation:animation forKey:nil];
                                    // 确保内存能及时释放掉
                                    [images enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                                        if (obj) {
//                                            NSLog(@"%@", obj);
                                            obj = nil;
                                            
                                            //            CGImageRelease((__bridge CGImageRef)obj);
                                        }
                                    }];
                                    //                           images = nil;
                                    //                           weakSelf.converter = nil;
                                }];
    
#else 
    
        NSString *videoFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/output2.mov"];//Get the Video from Bundle
        NSURL *videoFileURL = [NSURL fileURLWithPath: videoFilePath];//Convert the NSString To NSURL
        AVPlayer *player = [[AVPlayer alloc] initWithURL: videoFileURL]; // Create The AVPlayer With the URL
        AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer: player];//Place it to A Layer
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        playerLayer.frame = CGRectMake(0, 0, 300, 200);//Create A view frame size to match the view
    playerLayer.position = self.view.center;
        [self.view.layer addSublayer: playerLayer];//Add it to Player Layer
        [playerLayer setNeedsDisplay];// Set it to Display
        [player play];//Play it
        self.player = player;
    
    
#endif
    

    
    
    

    
}

- (void)dealloc
{
    [_preView.layer removeAllAnimations];
    _preView = nil;
    NSLog(@"");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
