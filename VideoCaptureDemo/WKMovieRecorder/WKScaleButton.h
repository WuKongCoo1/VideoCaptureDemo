//
//  WKScaleButton.h
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/19.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WKScaleButton : UIButton

@property (nonatomic,strong) CAShapeLayer *circleLayer;
@property (nonatomic,strong) UILabel *label;
-(void)disappearAnimation;
-(void)appearAnimation;

@end
