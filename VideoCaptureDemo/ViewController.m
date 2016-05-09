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
#import "WKPreviewView.h"

typedef NS_ENUM( NSInteger, CaptureAVSetupResult ) {
    CaptureAVSetupResultSuccess,
    CaptureAVSetupResultCameraNotAuthorized,
    CaptureAVSetupResultSessionConfigurationFailed
};

@interface ViewController ()
@property (weak, nonatomic) IBOutlet WKPreviewView *previewView;

@property (nonatomic, strong) AVCaptureSession *session;
@property (nonatomic, strong) AVCaptureDeviceInput *videoDeviceInput;
@property (nonatomic, strong) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic, strong) AVCaptureStillImageOutput *stillImageOutput;

@property (nonatomic, assign) CaptureAVSetupResult result;
@property (nonatomic, strong) dispatch_queue_t sessionQueue;

- (IBAction)still:(id)sender;
- (IBAction)recording:(id)sender;
- (IBAction)changeCamera:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
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
        
        AVCaptureDevice *captureDevice = [ViewController deviceWithMediaType:AVMediaTypeVideo preferringPosition:AVCaptureDevicePositionBack];
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
            
            UIInterfaceOrientation statusBarOrientation = [UIApplication sharedApplication].statusBarOrientation;
            AVCaptureVideoOrientation initialVideoOrientation = AVCaptureVideoOrientationPortrait;
            if ( statusBarOrientation != UIInterfaceOrientationUnknown ) {
                initialVideoOrientation = (AVCaptureVideoOrientation)statusBarOrientation;
            }
            
            AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
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
        
        //
        AVCaptureMovieFileOutput *movieOutput = [[AVCaptureMovieFileOutput alloc] init];
        if ([self.session canAddOutput:movieOutput]) {
            [self.session addOutput:movieOutput];
            self.movieFileOutput = movieOutput;
            
            AVCaptureConnection *connection = [movieOutput connectionWithMediaType:AVMediaTypeVideo];
            
            if (connection.isVideoStabilizationSupported) {
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            }
        }
        else{
            
            NSLog( @"Could not add movie file output to the session" );
            self.result = CaptureAVSetupResultSessionConfigurationFailed;
        }
        
        AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
        
        if ([self.session canAddOutput:stillImageOutput]) {
            stillImageOutput.outputSettings = @{AVVideoCodecKey : AVVideoCodecJPEG};
            
            [self.session addOutput:stillImageOutput];
            
            self.stillImageOutput = stillImageOutput;
            
        }
        else{
            NSLog( @"Could not add still image output to the session" );
            self.result = CaptureAVSetupResultSessionConfigurationFailed;
        }
        
        [self.session commitConfiguration];
    });
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.result == CaptureAVSetupResultSuccess) {
        [self.session startRunning];
    }
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

- (IBAction)still:(id)sender {
    
    dispatch_async(self.sessionQueue, ^{

        AVCaptureConnection *connection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
        AVCaptureVideoPreviewLayer *previewLayer = (AVCaptureVideoPreviewLayer *)self.previewView.layer;
        
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
}

- (IBAction)changeCamera:(id)sender {
}
@end
