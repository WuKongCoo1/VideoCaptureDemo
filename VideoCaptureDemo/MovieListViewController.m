//
//  MovieListViewController.m
//  VideoCaptureDemo
//
//  Created by 吴珂 on 16/5/16.
//  Copyright © 2016年 吴珂. All rights reserved.
//

#import "MovieListViewController.h"
#import "MovieCell.h"

@interface MovieListViewController ()
<
UITableViewDelegate,
UITableViewDataSource
>

@end

@implementation MovieListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
}


#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    [self configureCell:cell forRowAtIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(MovieCell *)cell
    forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *format;
#if TARGET_IPHONE_SIMULATOR
    
    format = @"/Users/wukong/Desktop/0.MOV";
#else
    
    format = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/%d.MOV"];
    
#endif
    NSString *videoFilePath = [NSString stringWithFormat:format, arc4random_uniform(4)];//Get the Video from Bundle
    NSURL *videoFileURL = [NSURL fileURLWithPath: videoFilePath];//Convert the NSString To NSURL
    [cell setupWithMovieUrl:videoFileURL];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 200.f;
}


-(void)dealloc
{
    NSLog(@"%s", __FUNCTION__);
}

@end
