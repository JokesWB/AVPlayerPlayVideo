//
//  LGMoviePlayerViewController.m
//  AVPlayer播放视频
//
//  Created by admin on 2016/10/31.
//  Copyright © 2016年 LaiCunBa. All rights reserved.
//

#import "LGMoviePlayerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "LGMoviePlayerView.h"

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
#define kTimeInterval 0.3f

@interface LGMoviePlayerViewController ()

@property (nonatomic , strong) LGMoviePlayerView *playerView;
@property (nonatomic , strong) AVPlayer *avPlayer;
@property (nonatomic , strong) AVPlayerItem *avPlayerItem;
@property (nonatomic , strong) AVPlayerLayer *avPlayerLayer;
@property (nonatomic , assign) CGFloat totalTime;  //视频总长度
@property (nonatomic , assign) BOOL playToEnd;   //播放完成
@property (nonatomic , assign) CGFloat currentSlideEndTime;   //滑动屏幕之后的秒数
@property (nonatomic , assign) CGFloat slideValue;   //滑动屏幕或滑块之后滑块的值
@property (nonatomic , assign) CGFloat currentSlideValue;    //滑动屏幕之后滑块的值
@property (nonatomic , assign) CGFloat currentVolume;   //当前音量值

@end

@implementation LGMoviePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    [self playerView];
    [self addClickActionForPlayerView];
    [self addObserver];
    [self configObserver];
    
    [self autoPlayMovie];
    
    [self playerViewHandelSwipeAction];
    
    self.currentVolume = 0.5;
    
}

//一进来就播放视频
- (void)autoPlayMovie
{
    [self.avPlayer play];
    [self addProgressSlideObserver];
    self.playerView.playOrPauseButton.selected = YES;
}

//添加通知
- (void)addObserver
{
    //播放结束
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playToEndTimeNotification:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //停止播放
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(PlaybackStalledNotification:) name:AVPlayerItemPlaybackStalledNotification object:nil];
    //播放失败
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(FailedToPlayToEndTimeNotification:) name:AVPlayerItemFailedToPlayToEndTimeNotification object:nil];
    //进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterBcakground:)
      name:UIApplicationWillResignActiveNotification object:nil];
    // 返回前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enterPlayGround:)
      name:UIApplicationDidBecomeActiveNotification object:nil];
    
}

- (void)playToEndTimeNotification:(NSNotification *)notify
{
    self.playerView.playOrPauseButton.selected = NO;
    self.playToEnd = YES;
}

- (void)PlaybackStalledNotification:(NSNotification *)notify
{
    self.playerView.playOrPauseButton.selected = NO;
}

- (void)FailedToPlayToEndTimeNotification:(NSNotification *)notify
{
    NSLog(@"播放失败了播放不到最后了");
}

- (void)enterBcakground:(NSNotification *)notify
{
    if (self.avPlayerItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.avPlayer pause];
    }
}

- (void)enterPlayGround:(NSNotification *)notify
{
    if (self.playToEnd) {
        return;
    }
    [self.avPlayer play];
}


//配置观察者
- (void)configObserver
{
    //播放状态
    [self.avPlayerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //缓冲进度
    [self.avPlayerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus playerItemStatus = [change[@"new"] integerValue];
        if (playerItemStatus == AVPlayerItemStatusReadyToPlay) {
            //准备播放
            CMTime totalTime = self.avPlayerItem.duration;
            CGFloat totalTimeSeconds = (CGFloat)totalTime.value / totalTime.timescale;
            NSLog(@"正在播放...，视频总长度:%.2f", totalTimeSeconds);
            self.totalTime = totalTimeSeconds;
            //设置总时间
            [self setTimeLabelTextWithLabel:self.playerView.totalTimeLabel CurrentOrTotalTime:totalTimeSeconds];
        }
        
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = self.avPlayerItem.loadedTimeRanges;
        //缓冲时间范围
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBufferTime = startSeconds + durationSeconds;
//        NSLog(@"缓冲------ %f", totalBufferTime / self.totalTime);
        //设置缓冲进度
        [self.playerView.progressView setProgress:totalBufferTime / self.totalTime animated:YES];
    }
}


- (void)addProgressSlideObserver
{
    AVPlayerItem *playerItem = self.avPlayer.currentItem;
    __weak typeof(self) weakSelf = self;
    [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1.0, 1.0) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        //获取当前进度
        CGFloat current = CMTimeGetSeconds(time);
        //获取全部资源大小
        CGFloat total = CMTimeGetSeconds([playerItem duration]);
        //计算进度
        if (current) {
            weakSelf.slideValue = current / total;
            [weakSelf.playerView.progressSlider setValue:(current / total) animated:YES];
            [weakSelf setTimeLabelTextWithLabel:weakSelf.playerView.playTimeLabel CurrentOrTotalTime:current];
        }
    }];
}


//设置电影URL
- (void)setMovieURLString:(NSString *)movieURLString
{
    _movieURLString = movieURLString;
    self.avPlayerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:movieURLString]];
    self.avPlayer = [AVPlayer playerWithPlayerItem:self.avPlayerItem];
    [self avPlayerLayer];
    
}

//设置电影名
- (void)setMovieName:(NSString *)movieName
{
    _movieName = movieName;
    self.playerView.movieName.text = movieName;
}


//给播放器界面添加按钮点击事件
- (void)addClickActionForPlayerView
{
    //返回按钮
    [self.playerView.backButton addTarget:self action:@selector(backButtonAction) forControlEvents:UIControlEventTouchUpInside];
    //播放按钮
    [self.playerView.playOrPauseButton addTarget:self action:@selector(playOrPauseButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    //滑块
    [self.playerView.progressSlider addTarget:self action:@selector(progressSliderAction:) forControlEvents:UIControlEventValueChanged];
    [self.playerView.progressSlider addTarget:self action:@selector(progressSliderEndAction:) forControlEvents:UIControlEventTouchUpInside];
    //全屏
    [self.playerView.fullScreenOrScaleScreenButton addTarget:self action:@selector(fullOrScaleScreenButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    
}


//播放器返回按钮
- (void)backButtonAction
{
    if (!self.playerView.fullScreenOrScaleScreenButton.selected) {
        [self.navigationController popViewControllerAnimated:YES];
        return;
    }
    self.playerView.isFullScreen = NO;
    [UIView animateWithDuration:kTimeInterval animations:^{
        self.playerView.volumeView.hidden = YES;
        [self.playerView setTransform:CGAffineTransformIdentity];
        self.playerView.frame = self.playerView.originFrame;
        self.avPlayerLayer.frame = self.playerView.bounds;
        [self.playerView layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.playerView.fullScreenOrScaleScreenButton.selected = NO;
    }];
    
}

//播放或暂停按钮
- (void)playOrPauseButtonAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
//        if (self.playToEnd) {
//            [self setMovieURLString:self.movieURLString];
//            self.playToEnd = NO;
//        }
        [self.avPlayer play];
        [self addProgressSlideObserver];
    } else {
        [self.avPlayer pause];
    }
    
}

//滑块滑动时，设为暂停
- (void)progressSliderAction:(UISlider *)sender
{
    //先暂停
    [self.avPlayer pause];
    self.playerView.playOrPauseButton.selected = NO;
    [self.playerView cancelAutoHidden];   //取消自动隐藏
    CGFloat current = (CGFloat)(self.totalTime * sender.value);
    [self setTimeLabelTextWithLabel:self.playerView.playTimeLabel CurrentOrTotalTime:current];
    
}

//拖动滑块松手后，设为播放
- (void)progressSliderEndAction:(UISlider *)sender
{
    CGFloat current = (CGFloat)(self.totalTime * sender.value);
    CMTime currentTime = CMTimeMake(current, 1);
    self.slideValue = sender.value;
    //记录当前播放时间
    self.currentSlideEndTime = (CGFloat)currentTime.value / currentTime.timescale;
    //给avplayer设置进度
    __weak typeof(self) weakSelf = self;
    [self.avPlayer seekToTime:currentTime completionHandler:^(BOOL finished) {
        weakSelf.playerView.playOrPauseButton.selected = YES;
        [weakSelf.avPlayer play];
        [weakSelf.playerView addAutoHidden];  //添加自动隐藏
    }];
}


//设置显示时间
- (void)setTimeLabelTextWithLabel:(UILabel *)label CurrentOrTotalTime:(CGFloat)time
{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:time];
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    if (time/3600 >=1) {
        [formatter setDateFormat:@"HH:mm:ss"];
    }else{
        [formatter setDateFormat:@"00:mm:ss"];
    }
    NSString * showTimeNew = [formatter stringFromDate:d];
    label.text = showTimeNew;
}

//全屏缩放按钮
- (void)fullOrScaleScreenButtonAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        //全屏
        self.playerView.isFullScreen = YES;
        CGRect frame = CGRectMake((kScreenW - kScreenH) / 2, (kScreenH - kScreenW) / 2, kScreenH, kScreenW);
        [UIView animateWithDuration:kTimeInterval animations:^{
            self.playerView.frame = frame;
            self.avPlayerLayer.frame = self.playerView.bounds;
            [self.playerView setTransform:CGAffineTransformMakeRotation(M_PI_2)];
            [self.playerView layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.playerView.backgroundColor = [UIColor clearColor];
            self.playerView.volumeView.hidden = NO;
        }];
    } else {
        //半屏
        self.playerView.isFullScreen = NO;
        self.playerView.volumeView.hidden = YES;
        [UIView animateWithDuration:kTimeInterval animations:^{
            [self.playerView setTransform:CGAffineTransformIdentity];
            self.playerView.frame = self.playerView.originFrame;
            self.avPlayerLayer.frame = self.playerView.bounds;
            [self.playerView layoutIfNeeded];
        }];
    }
}






//处理滑动屏幕
- (void)playerViewHandelSwipeAction
{
    __weak typeof(self) weakSelf = self;
    //滑动屏幕
    self.playerView.getOffsetX = ^(CGFloat scaleOffsetX) {
        
        weakSelf.playerView.playOrPauseButton.selected = NO;
        [weakSelf.avPlayer pause];  //先暂停
        //取消自动隐藏
        [weakSelf.playerView cancelAutoHidden];
        
        if (scaleOffsetX > 0) {
            //向右，前进
            scaleOffsetX = scaleOffsetX > 1 ? 1 : scaleOffsetX;
            CGFloat current = (CGFloat)(weakSelf.totalTime * scaleOffsetX) + weakSelf.currentSlideEndTime;
            current = current > weakSelf.totalTime ? weakSelf.totalTime : current;
            //设置当前播放时间
            [weakSelf setTimeLabelTextWithLabel:weakSelf.playerView.playTimeLabel CurrentOrTotalTime:current];
            //设置滑块进度
            weakSelf.currentSlideValue = (weakSelf.slideValue + scaleOffsetX) > 1 ? 1 : (weakSelf.slideValue + scaleOffsetX);
            [weakSelf.playerView.progressSlider setValue:weakSelf.currentSlideValue animated:NO];
//            NSLog(@"scaleOffsetX === %f, %f", scaleOffsetX, weakSelf.playerView.progressSlider.value);
        } else {
            //向左，后退
            if (weakSelf.currentSlideValue <= 0) {
                return;
            }
            //设置滑块进度
            weakSelf.currentSlideValue = (weakSelf.slideValue + scaleOffsetX) < 0 ? 0 : (weakSelf.slideValue + scaleOffsetX);
            [weakSelf.playerView.progressSlider setValue:weakSelf.currentSlideValue animated:NO];
            //设置当前播放时间
            CGFloat current = (CGFloat)(weakSelf.totalTime * scaleOffsetX) + weakSelf.currentSlideEndTime;
            current = current < 0 ? 0 : current;
            [weakSelf setTimeLabelTextWithLabel:weakSelf.playerView.playTimeLabel CurrentOrTotalTime:current];
//            NSLog(@"current = %f", current);
            
        }
    };
    
    //滑动结束
    self.playerView.touchesEnd = ^(){
//        NSLog(@"scaleOffsetXaaaa === %f", weakSelf.playerView.progressSlider.value);
        CGFloat current = (CGFloat)(weakSelf.totalTime * weakSelf.playerView.progressSlider.value);
        CMTime currentTime = CMTimeMake(current, 1);
        weakSelf.currentSlideEndTime = (CGFloat)currentTime.value / currentTime.timescale;
        weakSelf.slideValue = weakSelf.playerView.progressSlider.value;
        //给avplayer设置进度
        [weakSelf.avPlayer seekToTime:currentTime completionHandler:^(BOOL finished) {
            //播放
            [weakSelf.avPlayer play];
            [weakSelf.playerView addAutoHidden];  //添加自动隐藏
            weakSelf.playerView.playOrPauseButton.selected = YES;
        }];
    };
    
    //调节音量
    self.playerView.getVolumeValue = ^(CGFloat volumeValue) {
        //设置音量进度
        [weakSelf.playerView.volumeProgressView setProgress:volumeValue];
        [weakSelf.avPlayer setVolume:volumeValue];
    };
    
    
}


//播放器视图
- (LGMoviePlayerView *)playerView
{
    if (!_playerView) {
        _playerView = [[LGMoviePlayerView alloc] initWithFrame:CGRectMake(0, 0, kScreenW, kScreenW * 9 / 16) AddGestureRecognizer:YES];
        [self.view addSubview:_playerView];
        
    }
    return _playerView;
}


- (AVPlayerLayer *)avPlayerLayer
{
    if (!_avPlayerLayer) {
        _avPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
        _avPlayerLayer.frame = self.playerView.bounds;
        //视屏的填充模式,默认为AVLayerVideoGravityResizeAspect
        _avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        [self.playerView.layer insertSublayer:_avPlayerLayer atIndex:0];
    }
    return _avPlayerLayer;
}


//隐藏导航栏
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

//页面消失，停止播放
- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.avPlayer pause];
}

//隐藏状态栏
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)dealloc
{
    NSLog(@"dealloc");
    [self.avPlayerItem removeObserver:self forKeyPath:@"status"];
    [self.avPlayerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
