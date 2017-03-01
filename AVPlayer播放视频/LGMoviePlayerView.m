//
//  LGMoviePlayerView.m
//  AVPlayer播放视频
//
//  Created by admin on 2016/10/31.
//  Copyright © 2016年 LaiCunBa. All rights reserved.
//

#import "LGMoviePlayerView.h"

#define kScreenW [UIScreen mainScreen].bounds.size.width
#define kScreenH [UIScreen mainScreen].bounds.size.height
#define kTopOperationViewH 40
#define kBottomOprationViewH 40
#define kTimeLabelW 60
#define kMargin 5
#define kTimerDuration 5

//记录平移手势的起点
static CGPoint movePoint0;

@interface LGMoviePlayerView ()
{
    UIPanGestureRecognizer *moviePan;
}

@property (nonatomic , strong) NSTimer *timer;
@property (nonatomic , assign) BOOL ishidden;   //上下操作视图是否隐藏
@property (nonatomic , assign) BOOL isSetVolume;   //是否是设置音量
@property (nonatomic , assign) BOOL isSetMovie;   //是否是设置电影播放进度
@property (nonatomic , assign) CGFloat volume;    //音量
@property (nonatomic , assign) CGFloat offsetVol;  //加大或减小的音量

@end

@implementation LGMoviePlayerView

- (instancetype)initWithFrame:(CGRect)frame AddGestureRecognizer:(BOOL)addGesture
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.backgroundColor = [UIColor greenColor];
        [self setup];
        self.originFrame = self.frame;
        self.clipsToBounds = YES;
        
        //自动隐藏
        [self performSelector:@selector(autoHiddenOperationView) withObject:nil afterDelay:kTimerDuration];
        //单击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapAction:)];
        [self addGestureRecognizer:tap];
        //默认不添加平移手势
//        if (addGesture) {
//            [self addPanGestureRecognizer];
//        }
        
        //设置默认音量
        self.volume = 0.5;
        
    }
    return self;
}

- (void)setup
{
    [self topOperationView];
    [self backButton];
    [self movieName];
    [self playOrPauseButton];
    [self bottomOperationView];
    [self playTimeLabel];
    [self totalTimeLabel];
    [self progressView];
    [self progressSlider];
    [self fullScreenOrScaleScreenButton];
}

//屏幕平移手势
- (void)addPanGestureRecognizer
{
    moviePan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moviePanAction:)];
    [self addGestureRecognizer:moviePan];
}

//移除平移手势
- (void)removePanGestureRecognizer
{
    [moviePan removeTarget:self action:@selector(moviePanAction:)];
}

//单击
- (void)tapAction:(UITapGestureRecognizer *)tap
{
    CGPoint point = [tap locationInView:self];
    //如果点击的点不在上下操作视图上，则取消自动隐藏
    if (!CGRectContainsPoint(self.topOperationView.frame, point) && !CGRectContainsPoint(self.bottomOperationView.frame, point)) {
        [self hiddenOrShowOperationView];
    } else {
        [self cancelAutoHidden];
        // kTimerDuration秒之后，自动隐藏
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kTimerDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self hiddenOrShowOperationView];
        });
    }
}

//平移
- (void)moviePanAction:(UIPanGestureRecognizer *)pan
{
    CGPoint movePoint = [pan locationInView:self];
    if (pan.state == UIGestureRecognizerStateBegan) {
        //每次要进行平移时，都重新初始化一次
        self.ishidden = YES;
        [self hiddenOrShowOperationView];
        self.isSetVolume = YES;
        self.isSetMovie = YES;
        self.offsetVol = 0;
        //找到第一个触碰点
        movePoint0 = movePoint;
    }
    
    
    //如果滑动区域在上下部操作视图上，则不响应
    if (movePoint.y < kTopOperationViewH) return;
    
    if (self.frame.size.height == kScreenH) {
        if (movePoint.y > self.frame.size.width - kBottomOprationViewH) return;
    } else {
        if (movePoint.y > self.frame.size.height - kBottomOprationViewH) return;
    }
    
    
    //计算 X，Y 轴的偏移量
    CGFloat offsetX0 = movePoint.x - movePoint0.x;
    CGFloat offsetY0 = movePoint.y - movePoint0.y;
    
    
    //手势偏移角度
    CGFloat length = sqrtf(offsetY0 * offsetY0 + offsetX0 * offsetX0);
    float angle = sinf((offsetY0 / length));
    CGFloat countAngle = 180 * angle / M_PI;

    //音量调节
    if (countAngle < -40 || countAngle > 40) {
        if (self.isSetVolume) {
            //上滑，加大音量    ||    下滑，降低音量
            CGFloat offsetVolume = (movePoint0.y - movePoint.y) / 3000;
            if (offsetVolume >= 0 && offsetVolume > self.offsetVol) {
                // 上滑
                NSLog(@"上滑111");
                self.volume += offsetVolume;
            }
            
            if (offsetVolume >= 0 && offsetVolume < self.offsetVol) {
                //下滑
                NSLog(@"下滑333");
                self.volume = self.volume - (self.offsetVol - offsetVolume) * 10;
            }
            
            if (offsetVolume < 0 && offsetVolume < self.offsetVol) {
                //下滑
                NSLog(@"下滑444");
                self.volume += offsetVolume;
            }
            if (offsetVolume < 0 && offsetVolume > self.offsetVol) {
                //上滑
                NSLog(@"上滑222");
                self.volume = self.volume - (self.offsetVol - offsetVolume) * 10;
            }
            
            
            self.volume = self.volume >= 1 ? 1 : (self.volume <= 0 ? 0 : self.volume);
            
            
            if (self.getVolumeValue) {
                self.getVolumeValue(self.volume);
            }
            
            self.isSetMovie = NO;
            //记录上一次的音量偏移
            self.offsetVol = offsetVolume;
        }
        
    }

    //如果是刚触碰，则不执行下面的代码
    if (CGPointEqualToPoint(movePoint, movePoint0)) {
        return;
    }
    
    if (self.isSetMovie) {
        //滑动中
        if (pan.state == UIGestureRecognizerStateChanged) {
            CGFloat scaleOffsetX = offsetX0 / self.frame.size.height;
            if (self.getOffsetX) {
                self.getOffsetX(scaleOffsetX);
            }
        }
        //滑动结束
        if (pan.state == UIGestureRecognizerStateEnded) {
            [self hiddenOrShowOperationView];
            if (self.touchesEnd) {
                self.touchesEnd();
            }
        }
        self.isSetVolume = NO;
    }
    
    
    
    
}

- (void)layoutSubviews
{
    self.topOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), CGRectGetWidth(self.bounds), kTopOperationViewH);
    self.backButton.frame = CGRectMake(0, 0, kTopOperationViewH, kTopOperationViewH);
    self.movieName.frame = CGRectMake(kTopOperationViewH, 0, CGRectGetWidth(self.bounds) - kTopOperationViewH, kTopOperationViewH);
    self.playOrPauseButton.frame = CGRectMake(CGRectGetWidth(self.bounds) / 2 - kBottomOprationViewH / 2, CGRectGetHeight(self.bounds) / 2 - kBottomOprationViewH / 2, kBottomOprationViewH, kBottomOprationViewH);
    self.bottomOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds) - kBottomOprationViewH, CGRectGetWidth(self.bounds), kBottomOprationViewH);
    self.playTimeLabel.frame = CGRectMake(10, 0, kTimeLabelW, kBottomOprationViewH);
    self.progressView.frame = CGRectMake(CGRectGetMaxX(self.playTimeLabel.frame), kBottomOprationViewH / 2, CGRectGetWidth(self.bounds) - 2 * kTimeLabelW - kBottomOprationViewH - kMargin, kBottomOprationViewH);
    self.progressSlider.frame = self.progressView.frame;
    self.totalTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.progressView.frame) + kMargin, 0, kTimeLabelW, kBottomOprationViewH);
    self.fullScreenOrScaleScreenButton.frame = CGRectMake(CGRectGetMaxX(self.totalTimeLabel.frame), 0, kBottomOprationViewH, kBottomOprationViewH);
    self.volumeView.frame = CGRectMake(CGRectGetMinX(self.bounds) + 50, CGRectGetMinY(self.bottomOperationView.frame) - 60, 30, kScreenW - (kTopOperationViewH + kBottomOprationViewH) - 120);
    self.volumeProgressView.frame = self.volumeView.bounds;
}

//上部操作视图
- (UIView *)topOperationView
{
    if (!_topOperationView) {
        _topOperationView = [[UIView alloc] init];
        _topOperationView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        [self addSubview:_topOperationView];
    }
    return _topOperationView;
}

- (UIButton *)backButton
{
    if (!_backButton) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setBackgroundImage:[UIImage imageNamed:@"播放器_返回"] forState:UIControlStateNormal];
        [self.topOperationView addSubview:_backButton];
    }
    return _backButton;
}

- (UILabel *)movieName
{
    if (!_movieName) {
        _movieName = [[UILabel alloc] init];
        _movieName.text = @"我要看电影";
        _movieName.textColor = [UIColor whiteColor];
        [self.topOperationView addSubview:_movieName];
    }
    return _movieName;
}



//下部操作视图
- (UIView *)bottomOperationView
{
    if (!_bottomOperationView) {
        _bottomOperationView = [[UIView alloc] init];
        _bottomOperationView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.3];
        [self addSubview:_bottomOperationView];
    }
    return _bottomOperationView;
}

- (UIButton *)playOrPauseButton
{
    if (!_playOrPauseButton) {
        _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playOrPauseButton setBackgroundImage:[UIImage imageNamed:@"播放器_播放"] forState:UIControlStateNormal];
        [_playOrPauseButton setBackgroundImage:[UIImage imageNamed:@"播放器_暂停"] forState:UIControlStateSelected];
        [self addSubview:_playOrPauseButton];
    }
    return _playOrPauseButton;
}

- (UILabel *)playTimeLabel
{
    if (!_playTimeLabel) {
        _playTimeLabel = [[UILabel alloc] init];
        _playTimeLabel.text = @"00:00:00";
        _playTimeLabel.textColor = [UIColor whiteColor];
        _playTimeLabel.font = [UIFont systemFontOfSize:12];
        [self.bottomOperationView addSubview:_playTimeLabel];
    }
    return _playTimeLabel;
}

- (UIProgressView *)progressView
{
    if (!_progressView) {
        _progressView = [[UIProgressView alloc] init];
        _progressView.progress = 0.0f;
        _progressView.progressTintColor = [UIColor greenColor];
        _progressView.trackTintColor = [UIColor whiteColor];
        [self.bottomOperationView addSubview:_progressView];
    }
    return _progressView;
}

- (UISlider *)progressSlider
{
    if (!_progressSlider) {
        _progressSlider = [[UISlider alloc] initWithFrame:self.progressView.frame];
        _progressSlider.value = 0.0f;
        [_progressSlider setThumbImage:[UIImage imageNamed:@"thumb"] forState:UIControlStateNormal];
        _progressSlider.minimumTrackTintColor = [UIColor redColor];
        _progressSlider.maximumTrackTintColor = [UIColor clearColor];
        [self.bottomOperationView addSubview:_progressSlider];
    }
    return _progressSlider;
}

- (UILabel *)totalTimeLabel
{
    if (!_totalTimeLabel) {
        _totalTimeLabel = [[UILabel alloc] init];
        _totalTimeLabel.text = @"00:00:00";
        _totalTimeLabel.textColor = [UIColor whiteColor];
        _totalTimeLabel.font = [UIFont systemFontOfSize:12];
        [self.bottomOperationView addSubview:_totalTimeLabel];
    }
    return _totalTimeLabel;
}

- (UIButton *)fullScreenOrScaleScreenButton
{
    if (!_fullScreenOrScaleScreenButton) {
        _fullScreenOrScaleScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenOrScaleScreenButton setBackgroundImage:[UIImage imageNamed:@"播放器_音量"] forState:UIControlStateNormal];
        [_fullScreenOrScaleScreenButton setBackgroundImage:[UIImage imageNamed:@"播放器_静音"] forState:UIControlStateSelected];
        [self.bottomOperationView addSubview:_fullScreenOrScaleScreenButton];
    }
    return _fullScreenOrScaleScreenButton;
}

- (UIView *)volumeView
{
    if (!_volumeView) {
        _volumeView = [[UIView alloc] init];
        _volumeView.backgroundColor = [UIColor clearColor];
        _volumeView.layer.anchorPoint = CGPointMake(0, 0);
        _volumeView.transform = CGAffineTransformMakeRotation(-M_PI_2);
        _volumeView.hidden = YES;
        [self addSubview:_volumeView];
    }
    return _volumeView;
}

- (UIProgressView *)volumeProgressView
{
    if (!_volumeProgressView) {
        _volumeProgressView = [[UIProgressView alloc] init];
        _volumeProgressView.progress = 0.5;
        _volumeProgressView.trackTintColor = [UIColor whiteColor];
        _volumeProgressView.progressTintColor = [UIColor redColor];
        [self.volumeView addSubview:_volumeProgressView];
    }
    return _volumeProgressView;
}


//取消调用自动隐藏的方法
- (void)cancelAutoHidden
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoHiddenOperationView) object:nil];
}

//添加自动隐藏
- (void)addAutoHidden
{
    [self performSelector:@selector(autoHiddenOperationView) withObject:nil afterDelay:kTimerDuration];
}

//隐藏上下操作视图 和 音量进度条
- (void)hiddenOrShowOperationView
{
    self.ishidden = !self.ishidden;
    if (self.ishidden) {
        //隐藏
        [UIView animateWithDuration:0.3 animations:^{
            self.playOrPauseButton.alpha = 0;
            self.volumeView.hidden = YES;
            self.topOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), -kTopOperationViewH, CGRectGetWidth(self.bounds), kTopOperationViewH);
            self.bottomOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), kBottomOprationViewH);
        }];
    } else {
        //显示
        [UIView animateWithDuration:0.3 animations:^{
            self.playOrPauseButton.alpha = 1;
            if (self.isFullScreen == NO) {
                self.volumeView.hidden = YES;
            } else {
                self.volumeView.hidden = NO;
            }
            self.topOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetMinY(self.bounds), CGRectGetWidth(self.bounds), kTopOperationViewH);
            self.bottomOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds) - kBottomOprationViewH, CGRectGetWidth(self.bounds), kBottomOprationViewH);
        } completion:^(BOOL finished) {
            [self cancelAutoHidden];
            [self addAutoHidden];
        }];
    }
}

- (void)setIsFullScreen:(BOOL)isFullScreen
{
    _isFullScreen = isFullScreen;
    if (isFullScreen) {
        self.volumeView.hidden = NO;
        [self addPanGestureRecognizer];
    } else {
        self.volumeView.hidden = YES;
        [self removePanGestureRecognizer];
    }
}

//自动隐藏
- (void)autoHiddenOperationView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.playOrPauseButton.alpha = 0;
        self.volumeView.hidden = YES;
        self.topOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), -kTopOperationViewH, CGRectGetWidth(self.bounds), kTopOperationViewH);
        self.bottomOperationView.frame = CGRectMake(CGRectGetMinX(self.bounds), CGRectGetHeight(self.bounds), CGRectGetWidth(self.bounds), kBottomOprationViewH);
    } completion:^(BOOL finished) {
        self.ishidden = YES;
    }];
}



- (void)dealloc
{
    NSLog(@"移除了");
}

@end
