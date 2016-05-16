//
//  PlayViewController.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "PlayViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface PlayViewController ()

@property (nonatomic, strong) AVPlayer *player;

@end

@implementation PlayViewController



- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *videoFilePath = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.MOV"];//Get the Video from Bundle
    NSURL *videoFileURL = [NSURL fileURLWithPath: videoFilePath];//Convert the NSString To NSURL
    AVPlayer *player = [[AVPlayer alloc] initWithURL: videoFileURL]; // Create The AVPlayer With the URL
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer: player];//Place it to A Layer
    playerLayer.frame = self.view.frame;//Create A view frame size to match the view
    [self.view.layer addSublayer: playerLayer];//Add it to Player Layer
    [playerLayer setNeedsDisplay];// Set it to Display
    [player play];//Play it
    self.player = player;
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
