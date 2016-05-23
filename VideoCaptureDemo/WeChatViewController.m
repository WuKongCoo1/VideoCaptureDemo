//
//  WeChatViewController.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/18.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "WeChatViewController.h"



#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "WKPreviewView.h"
#import <Accelerate/Accelerate.h>
#import "WKMovieRecorder.h"
#import "WKScaleButton.h"

@import Photos;

static void *SessionRunningContext = &SessionRunningContext;
static void *CapturingStillImageContext = &CapturingStillImageContext;

typedef NS_ENUM( NSInteger, CaptureAVSetupResult ) {
    CaptureAVSetupResultSuccess,
    CaptureAVSetupResultCameraNotAuthorized,
    CaptureAVSetupResultSessionConfigurationFailed
};

typedef NS_ENUM( NSInteger, RecordingStatus )
{
    RecordingStatusIdle = 0,
    RecordingStatusStartingRecording,
    RecordingStatusRecording,
    RecordingStatusStoppingRecording,
};



@interface WeChatViewController ()
<
AVCaptureFileOutputRecordingDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate,
WKMovieRecorderDelegate
>

// For use in the storyboards.
@property (weak, nonatomic) IBOutlet WKPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *stillButton;
@property (weak, nonatomic) IBOutlet UIButton *recordingButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet WKScaleButton *longPressButton;

// Session management.
@property (nonatomic, strong) dispatch_queue_t sessionQueue;
@property (nonatomic, strong) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) NSDictionary *videoCompressionSettings;
@property (nonatomic, strong) NSDictionary *audioCompressionSettings;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *adaptor;


@property (nonatomic, strong) WKMovieRecorder *recorder;
@property (nonatomic, strong) AVAssetWriter *videoWriter;


@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic, strong)  AVAssetWriterInput *videoInput;
@property (nonatomic, strong) AVAssetWriterInput *audioInput;

// Utilities.
@property(readwrite) float videoFrameRate;
@property(readwrite) CMVideoDimensions videoDimensions;
@property (nonatomic, getter=isSessionRunning) BOOL sessionRunning;
@property (nonatomic) UIBackgroundTaskIdentifier backgroundRecordingID;
@property (nonatomic, assign) CaptureAVSetupResult result;
@property(nonatomic, readwrite) AVCaptureVideoOrientation videoOrientation;
@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputVideoFormatDescription;
@property(nonatomic, retain) __attribute__((NSObject)) CMFormatDescriptionRef outputAudioFormatDescription;

@property (nonatomic, strong) NSTimer *startTimer;
@property (nonatomic, strong) NSTimer *countDownTimer;
@property (nonatomic, assign, getter=isCountDownOver) BOOL countDownOver;

@property (nonatomic, assign, getter=isRecording) BOOL recording;
@property (nonatomic, assign, getter=isFinishRecording) BOOL finishRecording;

@property (nonatomic, assign) RecordingStatus status;
@property (nonatomic,) CMSampleBufferRef currentbuffer;

//Recording Utilities
@property (nonatomic, strong) NSTimer *recordingTimer;
@property (nonatomic, assign) NSInteger endState;
@property (nonatomic, assign) CGPoint tempPoint;

//preView
//@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;

//indicator
@property (nonatomic, strong) CALayer *processLayer;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;



- (IBAction)still:(id)sender;
- (IBAction)recording:(id)sender;
- (IBAction)changeCamera:(id)sender;
- (IBAction)play:(id)sender;

- (IBAction)camera:(id)sender;


@end

@implementation WeChatViewController
{
    BOOL _haveStartedSession;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    [self setupUI];
    
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
    
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"output2.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    _recorder = [[WKMovieRecorder alloc] initWithURL:[NSURL fileURLWithPath:outputPath]];
    _recorder.delegate = self;
    
//    [_recorder prepareRecording];
    
}

- (void)viewDidLayoutSubviews
{
    _processLayer.bounds = CGRectMake(0, 0, CGRectGetWidth(self.previewView.bounds), 5);
    _processLayer.position = CGPointMake(CGRectGetMidX(self.previewView.bounds), CGRectGetHeight(self.previewView.bounds) - 2.5);
    
    
//
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _processLayer.hidden = YES;
    static BOOL once = YES;
    
    if (once) {
        [_previewView setSession:self.session];
        once = NO;
    }
    dispatch_async(self.sessionQueue, ^{
        switch (self.result) {
            case CaptureAVSetupResultSuccess: {
                [self addObservers];
                
                [self.session startRunning];
                self.session.sessionPreset = AVCaptureSessionPresetHigh;
                self.sessionRunning = self.session.isRunning;
                break;
            }
            case CaptureAVSetupResultCameraNotAuthorized: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    // Provide quick access to Settings.
                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
                    }];
                    [alertController addAction:settingsAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                
                break;
            }
            case CaptureAVSetupResultSessionConfigurationFailed: {
                dispatch_async( dispatch_get_main_queue(), ^{
                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
                    [alertController addAction:cancelAction];
                    [self presentViewController:alertController animated:YES completion:nil];
                } );
                break;
            }
        }
    });
    
    
}

- (void)setupUI
{
    self.view.backgroundColor = [UIColor blackColor];
    
    UIBarButtonItem *cancleItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancle:)];
    
    self.navigationItem.leftBarButtonItem = cancleItem;
#define UsePanGesture 1
#if UsePanGesture
    
    UILongPressGestureRecognizer *panGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [self.longPressButton addGestureRecognizer:panGesture];
    
#else
    
    [self.longPressButton addTarget:self action:@selector(beginLongPress) forControlEvents:UIControlEventTouchDown];
    [self.longPressButton addTarget:self action:@selector(moveOut) forControlEvents:UIControlEventTouchUpOutside];
    [self.longPressButton addTarget:self action:@selector(endPress) forControlEvents:UIControlEventTouchUpInside];
    [self.longPressButton addTarget:self action:@selector(dragEnter) forControlEvents:UIControlEventTouchDragEnter];
    [self.longPressButton addTarget:self action:@selector(dragExit) forControlEvents:UIControlEventTouchDragExit];
    
#endif
    _processLayer = [CALayer layer];
}

- (void)panAction:(UILongPressGestureRecognizer *)ges
{
    switch (ges.state) {
        
        case UIGestureRecognizerStateBegan: {
            [self beginLongPress];

            break;
        }
        case UIGestureRecognizerStateChanged: {
            CGPoint point = [ges locationInView:self.longPressButton];
//            NSLog(@"poitn : %@", NSStringFromCGPoint(point));
            if (![self.longPressButton circleContainsPoint:point]) {
                
                [self dragExit];
                
                self.endState = 0;
                
            } else if ([self.longPressButton circleContainsPoint:point]) {
                self.endState = 1;
                [self dragEnter];

            }
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled: {
            NSLog(@"cancel, end");
            [self endPress];
            break;
        }
        case UIGestureRecognizerStateFailed: {
            NSLog(@"failed");
            
            break;
        }
        default:
            break;
    }
}


- (void)addAnimation
{
    _processLayer.hidden = NO;
    _processLayer.backgroundColor = [UIColor cyanColor].CGColor;
    
    CABasicAnimation *scaleXAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.x"];
    scaleXAnimation.duration = 10.f;
    scaleXAnimation.fromValue = @(1.f);
    scaleXAnimation.toValue = @(0.f);
    
    [_processLayer addAnimation:scaleXAnimation forKey:@"scaleXAnimation"];
}

- (void)removeAnimation
{
    [_processLayer removeAllAnimations];
    _processLayer.hidden = YES;
}

- (void)cancle:(id)sender
{
    
}

- (void)beginLongPress
{
    _countDownTimer = [NSTimer scheduledTimerWithTimeInterval:10.f target:self selector:@selector(endRecording) userInfo:nil repeats:NO];
    
    [self addAnimation];
    
    [self.longPressButton disappearAnimation];
    
    [self.previewView.layer addSublayer:_processLayer];
    [self.previewView addSubview:_statusLabel];
    
    [self setStatusLableHidden:NO isOut:NO];
    
    //开始录制
    [self benginRecording];
}

- (void)moveOut
{
    NSLog(@"%s", __FUNCTION__);
    [_countDownTimer invalidate];
    if (self.status == RecordingStatusStartingRecording) {
        [self finishRecording];
    }
}

- (void)endPress
{
    switch (self.endState) {
        case 0: {
            
            NSLog(@"取消发送");
            [self moveOut];
            break;
        }
        case 1: {
            
            NSLog(@"发送");
            NSLog(@"%s", __FUNCTION__);
            [_countDownTimer invalidate];
            if (self.status == RecordingStatusStartingRecording) {
                [self finishRecording];
            }
            break;
        }
        default:
            break;
    }
    
    
}

- (void)dragEnter
{
    NSLog(@"%s", __FUNCTION__);
    _processLayer.backgroundColor = [UIColor cyanColor].CGColor;
    
    [self setStatusLableHidden:NO isOut:NO];
}

- (void)dragExit
{
    _processLayer.backgroundColor = [UIColor redColor].CGColor;
    
//    NSLog(@"%@", _processLayer.backgroundColor);
    
    [self setStatusLableHidden:NO isOut:YES];
    
    NSLog(@"%s", __FUNCTION__);
    NSLog(@"松手取消");
}

- (void)endRecording
{
    self.status = RecordingStatusStoppingRecording;
    [self finishRecording];
    
}

- (void)setStatusLableHidden:(BOOL)hidden isOut:(BOOL)isOut
{
    self.statusLabel.hidden = hidden;
    
    if (isOut) {
        self.statusLabel.text = @"松手取消";
        self.statusLabel.backgroundColor = [UIColor redColor];
        self.statusLabel.textColor = [UIColor whiteColor];
        
    }else{
        
        self.statusLabel.text = @"向上滑动取消";
        self.statusLabel.backgroundColor = [UIColor clearColor];
        self.statusLabel.textColor = [UIColor cyanColor];
    }
}

- (void)setup
{
    self.sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    
    self.session = [[AVCaptureSession alloc] init];
    
    self.previewView.session = self.session;
    
    self.result = CaptureAVSetupResultSuccess;
    
    //权限检查
    switch ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo]) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    self.result = CaptureAVSetupResultSuccess;
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            
            break;
        }
        default:{
            self.result = CaptureAVSetupResultCameraNotAuthorized;
        }
    }
    
    
    
    dispatch_async(self.sessionQueue, ^{
        
        if ( self.result != CaptureAVSetupResultSuccess) {
            return;
        }
        
        AVCaptureDevice *captureDevice = [WeChatViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        
        _captureDevice = captureDevice;
        
        NSError *error = nil;
        _videoDeviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice error:&error];
        
        if (!_videoDeviceInput) {
            NSLog(@"未找到设备");
        }
        
        //配置会话
        [self.session beginConfiguration];
        
        //Video
        if ([self.session canAddInput:_videoDeviceInput]) {
            [self.session addInput:_videoDeviceInput];
            
            // Use the status bar orientation as the initial video orientation. Subsequent orientation changes are handled by
            // -[viewWillTransitionToSize:withTransitionCoordinator:].
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            
            AVCaptureVideoPreviewLayer *previewLayer = self.previewView.previewLayer;
            previewLayer.connection.videoOrientation = initialVideoOrientation;
        }
        else{
            NSLog(@"无法添加视频输入到会话");
        }
        
        //audio
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:&error];
        
        
        if ( ! audioDeviceInput ) {
            NSLog( @"Could not create audio device input: %@", error );
        }
        
        if ( [self.session canAddInput:audioDeviceInput] ) {
            [self.session addInput:audioDeviceInput];
            
        }
        else {
            NSLog( @"Could not add audio device input to the session" );
        }
        
        _videoDataOutputQueue = dispatch_queue_create( "com.apple.sample.capturepipeline.video", DISPATCH_QUEUE_SERIAL );
        dispatch_set_target_queue( _videoDataOutputQueue, dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH, 0 ) );
        
        AVCaptureVideoDataOutput *videoOut = [[AVCaptureVideoDataOutput alloc] init];
        _videoDataOutput = videoOut;
        videoOut.videoSettings = @{ (id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
        [videoOut setSampleBufferDelegate:self queue:_videoDataOutputQueue];
        
        videoOut.alwaysDiscardsLateVideoFrames = NO;
        
        if ( [_session canAddOutput:videoOut] ) {
            [_session addOutput:videoOut];
            _videoConnection = [videoOut connectionWithMediaType:AVMediaTypeVideo];
            
            if(_videoConnection.isVideoStabilizationSupported){
                _videoConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            
            _videoConnection.videoOrientation = initialVideoOrientation;
        }
        
        //        output.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
        //                                AVVideoCodecH264, AVVideoCodecKey,
        //                                [NSNumber numberWithInt:300], AVVideoWidthKey,
        //                                [NSNumber numberWithInt:300], AVVideoHeightKey,
        //                                AVVideoScalingModeResizeAspectFill,AVVideoScalingModeKey,
        //
        //                                nil];
        
        
        
        AVCaptureAudioDataOutput *audioOut = [[AVCaptureAudioDataOutput alloc] init];
        // Put audio on its own queue to ensure that our video processing doesn't cause us to drop audio
        dispatch_queue_t audioCaptureQueue = dispatch_queue_create( "com.apple.sample.capturepipeline.audio", DISPATCH_QUEUE_SERIAL );
        [audioOut setSampleBufferDelegate:self queue:audioCaptureQueue];
        
        
        if ( [self.session canAddOutput:audioOut] ) {
            [self.session addOutput:audioOut];
        }
        _audioConnection = [audioOut connectionWithMediaType:AVMediaTypeAudio];
        
        
        [self.session commitConfiguration];
    });
    
    
}

#pragma mark KVO and Notifications
- (void)addObservers
{
    [self.session addObserver:self forKeyPath:@"running" options:NSKeyValueObservingOptionNew context:SessionRunningContext];
    [self.stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:CapturingStillImageContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.videoDeviceInput.device];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRuntimeError:) name:AVCaptureSessionRuntimeErrorNotification object:self.session];
    // A session can only run when the app is full screen. It will be interrupted in a multi-app layout, introduced in iOS 9,
    // see also the documentation of AVCaptureSessionInterruptionReason. Add observers to handle these session interruptions
    // and show a preview is paused message. See the documentation of AVCaptureSessionWasInterruptedNotification for other
    // interruption reasons.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionWasInterrupted:) name:AVCaptureSessionWasInterruptedNotification object:self.session];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionInterruptionEnded:) name:AVCaptureSessionInterruptionEndedNotification object:self.session];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ( context == CapturingStillImageContext ) {
        BOOL isCapturingStillImage = [change[NSKeyValueChangeNewKey] boolValue];
        
        if ( isCapturingStillImage ) {
            dispatch_async( dispatch_get_main_queue(), ^{
                self.previewView.layer.opacity = 0.0;
                [UIView animateWithDuration:0.25 animations:^{
                    self.previewView.layer.opacity = 1.0;
                }];
            } );
        }
    }
    else if ( context == SessionRunningContext ) {
        BOOL isSessionRunning = [change[NSKeyValueChangeNewKey] boolValue];
        
        dispatch_async( dispatch_get_main_queue(), ^{
            // Only enable the ability to change camera if the device has more than one camera.
            self.cameraButton.enabled = isSessionRunning && ( [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count > 1 );
            self.recordingButton.enabled = isSessionRunning;
            self.stillButton.enabled = isSessionRunning;
        } );
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


- (void)subjectAreaDidChange:(NSNotification *)notification
{
    CGPoint devicePoint = CGPointMake( 0.5, 0.5 );
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)sessionRuntimeError:(NSNotification *)notification
{
    NSError *error = notification.userInfo[AVCaptureSessionErrorKey];
    NSLog( @"Capture session runtime error: %@", error );
    
    // Automatically try to restart the session running if media services were reset and the last start running succeeded.
    // Otherwise, enable the user to try to resume the session running.
    if ( error.code == AVErrorMediaServicesWereReset ) {
        dispatch_async( self.sessionQueue, ^{
            if ( self.isSessionRunning ) {
                [self.session startRunning];
                self.sessionRunning = self.session.isRunning;
            }
            else {
                dispatch_async( dispatch_get_main_queue(), ^{
                    //                    self.resumeButton.hidden = NO;
                } );
            }
        } );
    }
    else {
        //        self.resumeButton.hidden = NO;
    }
}

- (void)sessionWasInterrupted:(NSNotification *)notification
{
    // In some scenarios we want to enable the user to resume the session running.
    // For example, if music playback is initiated via control center while using AVCam,
    // then the user can let AVCam resume the session running, which will stop music playback.
    // Note that stopping music playback in control center will not automatically resume the session running.
    // Also note that it is not always possible to resume, see -[resumeInterruptedSession:].
    BOOL showResumeButton = NO;
    
    // In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
    if ( &AVCaptureSessionInterruptionReasonKey ) {
        AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
        NSLog( @"Capture session was interrupted with reason %ld", (long)reason );
        
        if ( reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient ||
            reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient ) {
            showResumeButton = YES;
        }
        else if ( reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps ) {
            // Simply fade-in a label to inform the user that the camera is unavailable.
            //            self.cameraUnavailableLabel.hidden = NO;
            //            self.cameraUnavailableLabel.alpha = 0.0;
            [UIView animateWithDuration:0.25 animations:^{
                //                self.cameraUnavailableLabel.alpha = 1.0;
            }];
        }
    }
    else {
        NSLog( @"Capture session was interrupted" );
        showResumeButton = ( [UIApplication sharedApplication].applicationState == UIApplicationStateInactive );
    }
    
    if ( showResumeButton ) {
        // Simply fade-in a button to enable the user to try to resume the session running.
        //        self.resumeButton.hidden = NO;
        //        self.resumeButton.alpha = 0.0;
        [UIView animateWithDuration:0.25 animations:^{
            //            self.resumeButton.alpha = 1.0;
        }];
    }
}

- (void)sessionInterruptionEnded:(NSNotification *)notification
{
    NSLog( @"Capture session interruption ended" );
    
    //    if ( ! self.resumeButton.hidden ) {
    //        [UIView animateWithDuration:0.25 animations:^{
    //            self.resumeButton.alpha = 0.0;
    //        } completion:^( BOOL finished ) {
    //            self.resumeButton.hidden = YES;
    //        }];
    //    }
    //    if ( ! self.cameraUnavailableLabel.hidden ) {
    //        [UIView animateWithDuration:0.25 animations:^{
    //            self.cameraUnavailableLabel.alpha = 0.0;
    //        } completion:^( BOOL finished ) {
    //            self.cameraUnavailableLabel.hidden = YES;
    //        }];
    //    }
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async( self.sessionQueue, ^{
        AVCaptureDevice *device = self.videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

+ (void)setFlashMode:(AVCaptureFlashMode)flashMode forDevice:(AVCaptureDevice *)device
{
    if ( device.hasFlash && [device isFlashModeSupported:flashMode] ) {
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            device.flashMode = flashMode;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    }
}

/**
 *  获取设备
 *
 *  @param mediaType 媒体类型
 *  @param position  捕获设备位置
 *
 *  @return 设备
 */
+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark - Actions
- (void)benginRecording
{
    [self.recorder setCropSize:self.previewView.bounds.size];
    [self.recorder prepareRecording];
    self.status = RecordingStatusStartingRecording;
    
    
    
    _haveStartedSession = NO;
}


- (void)finishRecording
{
    [self.longPressButton appearAnimation];
    [self setStatusLableHidden:YES isOut:NO];
    self.status = RecordingStatusStoppingRecording;
    [self.recorder finishRecording];
    
    [self removeAnimation];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription( sampleBuffer );
    
    if (self.status == RecordingStatusStartingRecording) {
        if ( connection == _videoConnection )
        {
            if ( self.outputVideoFormatDescription == nil ) {
                // Don't render the first sample buffer.
                // This gives us one frame interval (33ms at 30fps) for setupVideoPipelineWithInputFormatDescription: to complete.
                // Ideally this would be done asynchronously to ensure frames don't back up on slower devices.
                
                
                self.videoDimensions = CMVideoFormatDescriptionGetDimensions( formatDescription );
                
                self.outputVideoFormatDescription = formatDescription;
            }
            else {
                if (!_haveStartedSession) {
                    _haveStartedSession = YES;
                
                    
                    [self.recorder appendVideoBuffer:sampleBuffer];
                    
                }else{
                
                    [self.recorder appendVideoBuffer:sampleBuffer];
                
                }
            
            }
        }
        else if ( connection == _audioConnection )
        {
            self.outputAudioFormatDescription = formatDescription;
            
            @synchronized( self ) {
                
                [self.recorder appendAudioBuffer:sampleBuffer];
                
            }
            
        }
    }
}


#pragma mark - Orientation
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    // Note that the app delegate controls the device orientation notifications required to use the device orientation.
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = self.previewView.previewLayer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
        
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
        
        _videoConnection.videoOrientation = initialVideoOrientation;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration NS_DEPRECATED_IOS(2_0,8_0, "Implement viewWillTransitionToSize:withTransitionCoordinator: instead") __TVOS_PROHIBITED
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if ( UIDeviceOrientationIsPortrait( deviceOrientation ) || UIDeviceOrientationIsLandscape( deviceOrientation ) ) {
        AVCaptureVideoPreviewLayer *previewLayer = self.previewView.previewLayer;
        previewLayer.connection.videoOrientation = (AVCaptureVideoOrientation)deviceOrientation;
        
        UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
        AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
        if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
            initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
        }
        
        _videoConnection.videoOrientation = initialVideoOrientation;
    }
}

#pragma mark - WKMovieRecorderDelegate
- (void)movieRecorderDidFinishRecording:(WKMovieRecorder *)recorder
{
    self.status = RecordingStatusIdle;
}

#pragma mark - Camera
- (IBAction)camera:(id)sender {
    
    UIImagePickerController *ipc = [[UIImagePickerController alloc] init];
    
    ipc.sourceType =  UIImagePickerControllerSourceTypeCamera;
    
    ipc.delegate = self;
    
    ipc.allowsEditing = YES;
    
    ipc.videoQuality = UIImagePickerControllerQualityTypeMedium;
    
    ipc.videoMaximumDuration = 30.0f; // 30 seconds
    
    ///ipc.mediaTypes = [NSArray arrayWithObject:@"public.movie"];
    
    //主要是下边的两能数，@"public.movie", @"public.image"  一个是录像，一个是拍照
    
    ipc.mediaTypes = [NSArray arrayWithObjects:@"public.movie", @"public.image", nil];
    
    [self presentModalViewController:ipc animated:YES];
}
@end
