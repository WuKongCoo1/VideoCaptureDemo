//
//  WKProgressView.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/20.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "WKProgressView.h"

#define kTestCircleRadius 30.f

@interface WKProgressView ()

@property (nonatomic, strong) CAShapeLayer *borderLayer;
@property (nonatomic, strong) UIBezierPath *trackPath;
@property (nonatomic, strong) CAShapeLayer *progressLayer;
@property (nonatomic, strong) UIBezierPath *progressPath;

@end

@implementation WKProgressView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        //默认5
        self.progressWidth = 5;
    }
    return self;
}

- (void)setTrack
{
    _trackPath = [UIBezierPath bezierPathWithArcCenter:self.center radius:self.bounds.size.width / 2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];;
    self.borderLayer.path = _trackPath.CGPath;
}

- (void)setProgress
{
    _progressPath = [UIBezierPath bezierPathWithArcCenter:self.center radius:(self.bounds.size.width - 5) / 4 startAngle:- M_PI_2 endAngle:(M_PI * 2) * _progress - M_PI_2 clockwise:YES];
    self.progressLayer.path = _progressPath.CGPath;
}


- (void)setProgressWidth:(float)progressWidth
{
    _progressWidth = progressWidth;
    self.borderLayer.lineWidth = 1;
    self.progressLayer.lineWidth = (self.bounds.size.width - 5) / 2;
    
    [self setTrack];
    [self setProgress];
}

- (void)setBorderColor:(UIColor *)trackColor
{
    self.borderLayer.strokeColor = trackColor.CGColor;
}

- (void)setProgressColor:(UIColor *)progressColor
{
    self.progressLayer.strokeColor = progressColor.CGColor;
}

- (void)setProgress:(float)progress
{
    _progress = progress;
    
    [self setProgress];
}

- (void)setProgress:(float)progress animated:(BOOL)animated
{
    
}



#pragma mark - Lazy loading

- (CAShapeLayer *)borderLayer
{
    if (!_borderLayer) {
        _borderLayer = [CAShapeLayer new];
        [self.layer addSublayer:_borderLayer];
        _borderLayer.fillColor = nil;
        
        _borderLayer.lineCap = kCALineCapSquare;
    }
    return  _borderLayer;
}

- (CAShapeLayer *)progressLayer
{
    if (!_progressLayer) {
        _progressLayer = [CAShapeLayer new];
        _progressLayer.fillColor = nil;
        
        [self.layer addSublayer:_progressLayer];

    }
    return _progressLayer;
}

- (void)reset
{
    self.borderLayer.path = nil;
    self.progressLayer.path = nil;
}




@end
