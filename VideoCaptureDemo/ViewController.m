//
//  ViewController.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/9.
//  Copyright © 2016年 吴珂. All rights reserved.
//

@import Photos;

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import "WKPreviewView.h"
#import <Accelerate/Accelerate.h>
#import "WKMovieRecorder.h"



static void *SessionRunningContext = &SessionRunningContext;
static void *CapturingStillImageContext = &CapturingStillImageContext;

typedef NS_ENUM( NSInteger, CaptureAVSetupResult ) {
    CaptureAVSetupResultSuccess,
    CaptureAVSetupResultCameraNotAuthorized,
    CaptureAVSetupResultSessionConfigurationFailed
};

@interface ViewController ()
<
AVCaptureFileOutputRecordingDelegate,
AVCaptureVideoDataOutputSampleBufferDelegate,
AVCaptureAudioDataOutputSampleBufferDelegate
>

// For use in the storyboards.
@property (weak, nonatomic) IBOutlet WKPreviewView *previewView;
@property (weak, nonatomic) IBOutlet UIButton *stillButton;
@property (weak, nonatomic) IBOutlet UIButton *recordingButton;
@property (weak, nonatomic) IBOutlet UIButton *cameraButton;

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

@property (nonatomic, assign, getter=isRecording) BOOL recording;

@property (nonatomic,) CMSampleBufferRef currentbuffer;



- (IBAction)still:(id)sender;
- (IBAction)recording:(id)sender;
- (IBAction)changeCamera:(id)sender;
- (IBAction)play:(id)sender;


@end

@implementation ViewController
{
    BOOL _haveStartedSession;
}
//- (void)viewDidLoad {
//    [super viewDidLoad];
//    
//    
//    
//    [self setup];
//    
//    [self initVideoAudioWriter];
//    
//    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
//    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"output2.mov"];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
//        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
//    _recorder = [[WKMovieRecorder alloc] initWithURL:[NSURL fileURLWithPath:outputPath]];
//    
//    //    [self setupAVideoDataOutput];
//}
//
//- (void)viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    
//    dispatch_async(self.sessionQueue, ^{
//        switch (self.result) {
//            case CaptureAVSetupResultSuccess: {
//                [self addObservers];
//                
//                [self.session startRunning];
//                self.session.sessionPreset = AVCaptureSessionPresetHigh;
//                self.sessionRunning = self.session.isRunning;
//                break;
//            }
//            case CaptureAVSetupResultCameraNotAuthorized: {
//                dispatch_async( dispatch_get_main_queue(), ^{
//                    NSString *message = NSLocalizedString( @"AVCam doesn't have permission to use the camera, please change privacy settings", @"Alert message when the user has denied access to the camera" );
//                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
//                    [alertController addAction:cancelAction];
//                    // Provide quick access to Settings.
//                    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"Settings", @"Alert button to open Settings" ) style:UIAlertActionStyleDefault handler:^( UIAlertAction *action ) {
//                        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
//                    }];
//                    [alertController addAction:settingsAction];
//                    [self presentViewController:alertController animated:YES completion:nil];
//                } );
//                
//                break;
//            }
//            case CaptureAVSetupResultSessionConfigurationFailed: {
//                dispatch_async( dispatch_get_main_queue(), ^{
//                    NSString *message = NSLocalizedString( @"Unable to capture media", @"Alert message when something goes wrong during capture session configuration" );
//                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"AVCam" message:message preferredStyle:UIAlertControllerStyleAlert];
//                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString( @"OK", @"Alert OK button" ) style:UIAlertActionStyleCancel handler:nil];
//                    [alertController addAction:cancelAction];
//                    [self presentViewController:alertController animated:YES completion:nil];
//                } );
//                break;
//            }
//        }
//    });
//    
//    
//}

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
        
        AVCaptureDevice *captureDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
        
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

- (IBAction)still:(id)sender {
    
    dispatch_async(self.sessionQueue, ^{

        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = self.previewView.previewLayer;
        
        // Update the orientation on the still image output video connection before capturing.
        connection.videoOrientation = previewLayer.connection.videoOrientation;
        
        // Flash set to Auto for Still Capture.
        [ViewController setFlashMode:AVCaptureFlashModeAuto forDevice:self.videoDeviceInput.device];
        
        // Capture a still image.
        [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^( CMSampleBufferRef imageDataSampleBuffer, NSError *error ) {
            if ( imageDataSampleBuffer ) {
                // The sample buffer is not retained. Create image data before saving the still image to the photo library asynchronously.
                NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                    if ( status == PHAuthorizationStatusAuthorized ) {
                        // To preserve the metadata, we create an asset from the JPEG NSData representation.
                        // Note that creating an asset from a UIImage discards the metadata.
                        // In iOS 9, we can use -[PHAssetCreationRequest addResourceWithType:data:options].
                        // In iOS 8, we save the image to a temporary file and use +[PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:].
                        if ( [PHAssetCreationRequest class] ) {
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                [[PHAssetCreationRequest creationRequestForAsset] addResourceWithType:PHAssetResourceTypePhoto data:imageData options:nil];
                            } completionHandler:^( BOOL success, NSError *error ) {
                                if ( ! success ) {
                                    NSLog( @"Error occurred while saving image to photo library: %@", error );
                                }
                            }];
                        }
                        else {
                            NSString *temporaryFileName = [NSProcessInfo processInfo].globallyUniqueString;
                            NSString *temporaryFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[temporaryFileName stringByAppendingPathExtension:@"jpg"]];
                            NSURL *temporaryFileURL = [NSURL fileURLWithPath:temporaryFilePath];
                            
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                NSError *error = nil;
                                [imageData writeToURL:temporaryFileURL options:NSDataWritingAtomic error:&error];
                                if ( error ) {
                                    NSLog( @"Error occured while writing image data to a temporary file: %@", error );
                                }
                                else {
                                    [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:temporaryFileURL];
                                }
                            } completionHandler:^( BOOL success, NSError *error ) {
                                if ( ! success ) {
                                    NSLog( @"Error occurred while saving image to photo library: %@", error );
                                }
                                
                                // Delete the temporary file.
                                [[NSFileManager defaultManager] removeItemAtURL:temporaryFileURL error:nil];
                            }];
                        }
                    }
                }];
            }
            else {
                NSLog( @"Could not capture still image: %@", error );
            }
        }];
    });
    

    
}


- (IBAction)recording:(id)sender {
    
    self.cameraButton.enabled = NO;
    
    if (self.isRecording) {

        [self.videoInput markAsFinished];
        
        [self.videoWriter finishWritingWithCompletionHandler:^{
            NSLog(@"写完了");

        }];
        self.recording = NO;
    }else{

        
        NSString *filePath = [[self.videoWriter.outputURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDirectory]) {
            if ([[NSFileManager defaultManager] removeItemAtURL:self.videoWriter.outputURL error:nil]) {
                NSLog(@"");
            }
        }
      [self initVideoAudioWriter];
        switch (self.videoWriter.status) {
            case AVAssetWriterStatusUnknown:{
                [self.videoWriter startWriting];
            }
                
                break;
                
            default:
            {
                
            }
                break;
        }
    
        self.recording = YES;
        _haveStartedSession = NO;
        
        
        
    }
    
//    dispatch_async(self.sessionQueue, ^{
//       
//        if (!self.movieFileOutput.isRecording) {
//            
//            if ([[UIDevice currentDevice] isMultitaskingSupported]) {
//                self.backgroundRecordingID = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
//            }
//            
//            //更新vedio方向
//            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
//            AVCaptureVideoPreviewLayer *previewLayer = self.previewView.previewLayer;
//            connection.videoOrientation = previewLayer.connection.videoOrientation;
//            
//            //关闭闪关灯模式
//            [ViewController setFlashMode:AVCaptureFlashModeOff forDevice:self.videoDeviceInput.device];
//             
//            //写入文件
//            
//            NSString *outputFileName = [NSProcessInfo processInfo].globallyUniqueString;
//            NSString *outputDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:[outputFileName stringByAppendingPathExtension:@"mov"]];
//            
//            [self.movieFileOutput startRecordingToOutputFileURL:[NSURL fileURLWithPath:outputDirectory] recordingDelegate:self];
//            
//            [self.videoDataOutput recommendedVideoSettingsForAssetWriterWithOutputFileType:AVFileTypeQuickTimeMovie];
//            
//            [self.recorder prepareToRecord];
//            
//        }else{
//            [self.movieFileOutput stopRecording];
//            [self.recorder finishRecording];
//        }
//        
//    });
    
}

- (IBAction)changeCamera:(id)sender {
    dispatch_async(self.sessionQueue, ^{
        
        AVCaptureDevice *captureDevice           = self.videoDeviceInput.device;

        AVCaptureDevicePosition preferredPostion = AVCaptureDevicePositionUnspecified;
        AVCaptureDevicePosition currentPosotion  = captureDevice.position;
        
        switch (currentPosotion) {
            case AVCaptureDevicePositionUnspecified:
            case AVCaptureDevicePositionFront: {
                preferredPostion = AVCaptureDevicePositionBack;
                break;
            }
            case AVCaptureDevicePositionBack: {
                preferredPostion = AVCaptureDevicePositionFront;
                break;
            }
        }
        
        AVCaptureDevice *newDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPostion];
        NSError *error = nil;
        AVCaptureDeviceInput *newDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:newDevice error:&error];
        
        [self.session beginConfiguration];
        
        [self.session removeInput:self.videoDeviceInput];
        
        if ([self.session canAddInput:newDeviceInput]) {
            //TODO: 通知处理
            
            //设置闪光模式
            [ViewController setFlashMode:AVCaptureFlashModeAuto forDevice:newDevice];
            
            
            [self.session addInput:newDeviceInput];
            
            self.videoDeviceInput = newDeviceInput;
            
            AVCaptureConnection *connection = [self.movieFileOutput connectionWithMediaType:AVMediaTypeVideo];
            
            if ([connection isVideoStabilizationSupported]) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
            
        }
        else{
            [self.session addInput:self.videoDeviceInput];
        }
        
        [self.session commitConfiguration];
        
    });
}

- (IBAction)play:(id)sender {
}


#pragma mark - AVCaptureFileOutputRecordingDelegate
- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    self.cameraButton.enabled = YES;
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    NSLog(@"%lu", (unsigned long)self.backgroundRecordingID);
    UIBackgroundTaskIdentifier currentBackgroundRecordingID = self.backgroundRecordingID;
    self.backgroundRecordingID = UIBackgroundTaskInvalid;
    
    dispatch_block_t cleanup = ^{
        [[NSFileManager defaultManager] removeItemAtURL:outputFileURL error:nil];
        if ( currentBackgroundRecordingID != UIBackgroundTaskInvalid ) {
            [[UIApplication sharedApplication] endBackgroundTask:currentBackgroundRecordingID];
        }
    };
    BOOL success = YES;
    
    if ( error ) {
        NSLog( @"Movie file finishing error: %@", error );
        success = [error.userInfo[AVErrorRecordingSuccessfullyFinishedKey] boolValue];
    }
    
    if ( success ) {
        
        [self filePath:[outputFileURL absoluteString]];
        
    }
    else {
        cleanup();
    }
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription( sampleBuffer );
    
    if (self.isRecording) {
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
                    if (self.videoWriter.status != AVAssetExportSessionStatusUnknown) {
                        [self.videoWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                        _currentbuffer = sampleBuffer;
                        [self.videoInput appendSampleBuffer:sampleBuffer];
                    }
                    
                }else{
                    _currentbuffer = sampleBuffer;
                    [self.videoInput appendSampleBuffer:sampleBuffer];
                }
                
            }
        }
        else if ( connection == _audioConnection )
        {
            self.outputAudioFormatDescription = formatDescription;
            
            @synchronized( self ) {
                if (self.videoWriter.status != AVAssetExportSessionStatusUnknown) {
                    [self.audioInput appendSampleBuffer:sampleBuffer];
                }
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

#pragma mark - CropVideo
- (void)filePath:(NSString *)filePath
{
    // output file
    NSString* docFolder = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString* outputPath = [docFolder stringByAppendingPathComponent:@"output2.mov"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outputPath])
        [[NSFileManager defaultManager] removeItemAtPath:outputPath error:nil];
    
    // input file
    AVAsset* asset = [AVAsset assetWithURL:[NSURL URLWithString:filePath]];
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    [composition  addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    // input clip
    AVAssetTrack *clipVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    
    // make it square
    AVMutableVideoComposition* videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize = CGSizeMake(300, 200);
    videoComposition.frameDuration = CMTimeMake(1, 30);
    
    AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(60, 30) );
    
    // rotate to portrait
    AVMutableVideoCompositionLayerInstruction* transformer = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:clipVideoTrack];
//    CGAffineTransform t1 = CGAffineTransformMakeTranslation(300, -(200- 300) /2 );
//    CGAffineTransform t2 = CGAffineTransformRotate(t1, M_PI_2);
    
//    CGAffineTransform finalTransform = t2;
//    [transformer setTransform:finalTransform atTime:kCMTimeZero];
//    instruction.layerInstructions = [NSArray arrayWithObject:transformer];
    videoComposition.instructions = [NSArray arrayWithObject: instruction];
    
    // export
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:asset presetName:AVAssetExportPresetHighestQuality] ;
    exporter.videoComposition = videoComposition;
    exporter.outputURL=[NSURL fileURLWithPath:outputPath];
    exporter.outputFileType=AVFileTypeQuickTimeMovie;
    
    [exporter exportAsynchronouslyWithCompletionHandler:^(void){
        NSLog(@"%@", exporter);
        NSLog(@"Exporting done!");
        [PHPhotoLibrary requestAuthorization:^( PHAuthorizationStatus status ) {
                        if ( status == PHAuthorizationStatusAuthorized ) {
                            // Save the movie file to the photo library and cleanup.
                            [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
                                // In iOS 9 and later, it's possible to move the file into the photo library without duplicating the file data.
                                // This avoids using double the disk space during save, which can make a difference on devices with limited free disk space.
                                if ( [PHAssetResourceCreationOptions class] ) {
                                    PHAssetResourceCreationOptions *options = [[PHAssetResourceCreationOptions alloc] init];
                                    options.shouldMoveFile = YES;
                                    PHAssetCreationRequest *changeRequest = [PHAssetCreationRequest creationRequestForAsset];
                                    [changeRequest addResourceWithType:PHAssetResourceTypeVideo fileURL:[NSURL fileURLWithPath:outputPath] options:options];
                                }
                                else {
                                    [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:outputPath]];
                                }
                            } completionHandler:^( BOOL success, NSError *error ) {
                                if ( ! success ) {
                                    NSLog( @"Could not save movie to photo library: %@", error );
                                }
                                
                            }];
                        }
                        else {
                            
                        }
                    }];

    }];
    
}

-(void) initVideoAudioWriter
{
    //视频图像范围
//    CGSize size = CGSizeMake(200, 200); 
    
    //刻录视频文件生成路径
    NSString *betaCompressionDirectory = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.MOV"];
    
    NSError *error = nil;
    
    unlink([betaCompressionDirectory UTF8String]);
    //添加图像输入
    //--------------------------------------------初始化刻录机--------------------------------------------
    self.videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:betaCompressionDirectory]
                                                 fileType:AVFileTypeQuickTimeMovie
                                                    error:&error];
    NSParameterAssert(self.videoWriter);
    
    if(error) NSLog(@"error = %@", [error localizedDescription]);
    //--------------------------------------------------------------------------------------------------
    
    
    
    
    
    //--------------------------------------------初始化图像信息输入参数--------------------------------------------
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:300], AVVideoWidthKey,
                                   [NSNumber numberWithInt:200],AVVideoHeightKey,
                                   AVVideoScalingModeResizeAspectFill,AVVideoScalingModeKey,
                                   nil];
    
    self.videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    NSParameterAssert(self.videoInput);
    self.videoInput.expectsMediaDataInRealTime = YES;
    //--------------------------------------------------------------------------------------------------
    
    
    
    
    
    //--------------------------------------------缓冲区参数设置--------------------------------------------
    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.adaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.videoInput
                    
                                                                                    sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    
    NSParameterAssert(self.videoInput);
    
    NSParameterAssert([self.videoWriter canAddInput:self.videoInput]);
    //--------------------------------------------------------------------------------------------------
    
    
    
    //添加音频输入
    
    AudioChannelLayout acl;
    
    bzero( &acl, sizeof(acl));
    
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
    
    
    //音频配置
    NSDictionary* audioOutputSettings = nil;
    audioOutputSettings = [ NSDictionary dictionaryWithObjectsAndKeys:
                           
                           [ NSNumber numberWithInt: kAudioFormatMPEG4AAC ], AVFormatIDKey,
                           
                           [ NSNumber numberWithInt:64000], AVEncoderBitRateKey,
                           
                           [ NSNumber numberWithFloat: 44100.0 ], AVSampleRateKey,
                           
                           [ NSNumber numberWithInt: 1 ], AVNumberOfChannelsKey,
                           
                           [ NSData dataWithBytes: &acl length: sizeof( acl ) ], AVChannelLayoutKey,
                           
                           nil ];
    
    
    
    self.audioInput = [AVAssetWriterInput  assetWriterInputWithMediaType: AVMediaTypeAudio
                                                                outputSettings: audioOutputSettings];
    self.audioInput.expectsMediaDataInRealTime = YES;
    
    
    
    //图像和语音输入添加到刻录机
    [self.videoWriter addInput:self.audioInput];
    
    [self.videoWriter addInput:self.videoInput];
    
}


@end
