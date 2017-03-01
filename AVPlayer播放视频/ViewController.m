//
//  ViewController.m
//  AVPlayer播放视频
//
//  Created by admin on 2016/10/31.
//  Copyright © 2016年 LaiCunBa. All rights reserved.
//

#import "ViewController.h"
#import "LGMoviePlayerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"电影";
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.frame = CGRectMake(100, 100, 100, 100);
    [button setTitle:@"下一页" forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont systemFontOfSize:20];
    button.backgroundColor = [UIColor redColor];
    button.layer.cornerRadius = 5;
    button.layer.masksToBounds = YES;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
}

- (void)buttonAction
{
    LGMoviePlayerViewController *playerVC = [[LGMoviePlayerViewController alloc] init];
    playerVC.movieURLString = @"http://krtv.qiniudn.com/150522nextapp";
    playerVC.movieName = @"下一个应用";
    [self.navigationController pushViewController:playerVC animated:YES];
}

@end
