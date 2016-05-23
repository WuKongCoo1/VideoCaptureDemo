//
//  WKScaleButton.h
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/19.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WKScaleButton : UIView

@property (nonatomic,strong) CAShapeLayer *circleLayer;
@property (nonatomic,strong) UILabel *label;
@property (nonatomic, readonly) CGFloat radius;

-(void)disappearAnimation;
-(void)appearAnimation;

- (BOOL)circleContainsPoint:(CGPoint)point;

@end
