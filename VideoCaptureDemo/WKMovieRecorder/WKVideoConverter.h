//
//  WKVideoConverter.h
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^block)(void);

@interface WKVideoConverter : NSObject

+ (void)shareInstance;

- (void)convertVideoToImagesWithURL:(NSURL *)url finishBlock:(void (^)(NSArray *images))finishBlock;

@end
