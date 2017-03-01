//
//  LGMoviePlayerView.h
//  AVPlayer播放视频
//
//  Created by admin on 2016/10/31.
//  Copyright © 2016年 LaiCunBa. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LGMoviePlayerView : UIView

@property (nonatomic , assign) CGRect originFrame;

//上部操作视图
@property (nonatomic , strong) UIView *topOperationView;
//上部操作视图上的返回按钮
@property (nonatomic , strong) UIButton *backButton;
//上部操作视图上的标题，电影名字
@property (nonatomic , strong) UILabel *movieName;



//下部操作视图
@property (nonatomic , strong) UIView *bottomOperationView;
//播放时间
@property (nonatomic , strong) UILabel *playTimeLabel;
//电影总时长
@property (nonatomic , strong) UILabel *totalTimeLabel;
//播放或暂停按钮
@property (nonatomic , strong) UIButton *playOrPauseButton;
//全屏或部分屏幕播放按钮
@property (nonatomic , strong) UIButton *fullScreenOrScaleScreenButton;
//播放进度
@property (nonatomic , strong) UISlider *progressSlider;
//缓冲进度
@property (nonatomic , strong) UIProgressView *progressView;
//音量进度条的父视图
@property (nonatomic , strong) UIView *volumeView;
//音量进度
@property (nonatomic , strong) UIProgressView *volumeProgressView;



//滑动屏幕前进或后退
@property (nonatomic , copy) void (^getOffsetX) (CGFloat scaleOffsetX);
//滑动结束
@property (nonatomic , copy) dispatch_block_t touchesEnd;
//音量调节
@property (nonatomic , copy) void(^getVolumeValue) (CGFloat volumeValue);
//是否全屏，默认为NO
@property (nonatomic , assign) BOOL isFullScreen;


//初始化
- (instancetype)initWithFrame:(CGRect)frame AddGestureRecognizer:(BOOL)addGesture;

//添加屏幕平移手势
- (void)addPanGestureRecognizer;
//移除平移手势
- (void)removePanGestureRecognizer;

//取消调用自动隐藏的方法
- (void)cancelAutoHidden;

//添加自动隐藏
- (void)addAutoHidden;



@end
