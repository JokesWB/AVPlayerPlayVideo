//
//  LGMoviePlayerViewController.h
//  AVPlayer播放视频
//
//  Created by admin on 2016/10/31.
//  Copyright © 2016年 LaiCunBa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LGMoviePlayerViewController : UIViewController

//播放视频地址
@property (nonatomic , copy) NSString *movieURLString;
//电影名称
@property (nonatomic , copy) NSString *movieName;

@end
