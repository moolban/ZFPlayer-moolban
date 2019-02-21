//
//  ViewVideoPlayerControler.m
//  ZFPlayer_Example
//
//  Created by WonSang Ryu on 2018. 7. 27..
//  Copyright © 2018년 紫枫. All rights reserved.
//

#import "ViewVideoPlayerControler.h"
#import <AVKit/AVKit.h>
#import <AVFoundation/AVFoundation.h>
#import "UIView+ZFFrame.h"
#import "ZFSliderView.h"
#import "ZFUtilities.h"
#import "UIImageView+ZFCache.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ZFVolumeBrightnessView.h"

#if __has_include(<ZFPlayer-moolban/ZFPlayer.h>)
#import <ZFPlayer-moolban/ZFPlayer.h>
#else
#import "ZFPlayer.h"
#endif

static const CGFloat ZFPlayerAnimationTimeInterval              = 2.5f;
static const CGFloat ZFPlayerControlViewAutoFadeOutTimeInterval = 0.25f;

@interface ViewVideoPlayerControler () <ZFSliderViewDelegate>
/// 是否显示了控制层
@property (nonatomic, assign, getter=isShowing) BOOL showing;
/// 是否播放结束
@property (nonatomic, assign, getter=isPlayEnd) BOOL playeEnd;

@property (nonatomic, assign) BOOL controlViewAppeared;

@property (nonatomic, assign) NSTimeInterval sumTime;

@property (nonatomic, strong) dispatch_block_t afterBlock;

@property (nonatomic, strong) ZFVolumeBrightnessView *volumeBrightnessView;



@property (nonatomic, assign) BOOL isShow;

@end

@implementation ViewVideoPlayerControler
@synthesize player = _player;

- (instancetype)init
{
    self = [self initWithFrame:[[[UIApplication sharedApplication] keyWindow] bounds]];
    if (self) {
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
        
        [self initData];
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        if ([self frame].size.width == 0 && [self frame].size.height == 0) {
            return self;
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(volumeChanged:)
                                                     name:@"AVSystemController_SystemVolumeDidChangeNotification"
                                                   object:nil];
        
        [self initData];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initData];
    }
    return self;
}

- (void)awakeFromNib{
    [super awakeFromNib];
    [self setup];
}

- (void)prepareForInterfaceBuilder{
    [super prepareForInterfaceBuilder];
    [self setup];
}

- (void)initNib{
    view = [[[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] objectAtIndex:0];
    [view setFrame:self.bounds];
    [self setConstraint:view];
    [self addSubview:view];
}

- (void)setConstraint:(UIView *)view {
    view.translatesAutoresizingMaskIntoConstraints = NO;
    NSLayoutConstraint *viewWidth =  [NSLayoutConstraint constraintWithItem:view
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self
                                                                  attribute:NSLayoutAttributeWidth
                                                                 multiplier:1
                                                                   constant:0];
    
    
    NSLayoutConstraint *viewHeight =  [NSLayoutConstraint constraintWithItem:view
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:self
                                                                   attribute:NSLayoutAttributeHeight
                                                                  multiplier:1
                                                                    constant:0];
    
    NSLayoutConstraint *centerX = [NSLayoutConstraint constraintWithItem:view
                                                               attribute:NSLayoutAttributeCenterX
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeCenterX
                                                              multiplier:1
                                                                constant:0];
    
    NSLayoutConstraint *centerY = [NSLayoutConstraint constraintWithItem:view
                                                               attribute:NSLayoutAttributeCenterY
                                                               relatedBy:NSLayoutRelationEqual
                                                                  toItem:self
                                                               attribute:NSLayoutAttributeCenterY
                                                              multiplier:1
                                                                constant:0];
    
    [self addConstraints:[NSArray arrayWithObjects:viewWidth,viewHeight,centerX,centerY,nil]];
}

- (void)initData{
    _showBtnMsg = YES;
}

- (void)setup{
    [self initNib];
    [self initUI];
    [self setEvent];
    [self resetControlView];
}

- (void)initUI{
    @weakify(self)
    [self setSliderValueChanging:^(CGFloat value, BOOL forward) {
        @strongify(self)
        [self cancelAutoFadeOutControlView];
    }];
    [self setSliderValueChanged:^(CGFloat value) {
        @strongify(self)
        [self autoFadeOutControlView];
    }];
    
    [_slider setDelegate:self];
    [_slider setMaximumTrackTintColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:0.8]];
    [_slider setBufferTrackTintColor:[UIColor colorWithRed:1 green:1 blue:1 alpha:0.5]];
    [_slider setMinimumTrackTintColor:[UIColor whiteColor]];
    [_slider setThumbImage:[UIImage imageNamed:@"ZFPlayer_slider"] forState:UIControlStateNormal];
    [_slider setSliderHeight:2];
    
    [self addAllSubViews];
}

- (void)setEvent{
    [_failBtn addTarget:self action:@selector(failBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [_backBtn addTarget:self action:@selector(backBtnClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [_playOrPauseBtn addTarget:self action:@selector(playPauseButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [_centerPlayOrPauseBtn addTarget:self action:@selector(playPauseButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    
    [_soundBtn addTarget:self action:@selector(soundButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
    [_fullScreenBtn addTarget:self action:@selector(fullScreenButtonClickAction:) forControlEvents:UIControlEventTouchUpInside];
}


- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat min_x = 0;
    CGFloat min_y = 0;
    CGFloat min_w = 0;
    CGFloat min_h = 0;
    
    min_x = 0;
    min_y = 0;
    min_w = 160;
    min_h = 40;
    self.volumeBrightnessView.frame = CGRectMake(min_x, min_y, min_w, min_h);
    self.volumeBrightnessView.center = self.center;
    
    if (!self.isShow) {
        [_consBottmoToolB setConstant:-_bottomToolView.frame.size.height];
        self.playOrPauseBtn.alpha = 0;
        self.backBtn.alpha = 0;
    } else {
        [_consBottmoToolB setConstant:0];
        //        self.bottomToolView.y = self.height - self.bottomToolView.height;
        self.playOrPauseBtn.alpha = 1;
        self.backBtn.alpha = 1;
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVSystemController_SystemVolumeDidChangeNotification" object:nil];
    [self cancelAutoFadeOutControlView];
    
    [_ivPlay release];
    [_activity release];
    [_vFail release];
    [_failBtn release];
    [_coverImageView release];
    [_volumeBrightnessView release];
    
    [_portraitControlView release];
    [_backBtn release];
    [_bottomToolView release];
    [_playOrPauseBtn release];
    [_currentTimeLabel release];
    [_slider release];
    [_totalTimeLabel release];
    [_soundBtn release];
    [_fullScreenBtn release];
    
    [_btnMsg release];
    [_consBottmoToolB release];
    [_centerPlayOrPauseBtn release];
    [super dealloc];
}

/// 添加所有子控件
- (void)addAllSubViews {
    [self addSubview:self.volumeBrightnessView];
}

- (void)autoFadeOutControlView {
    self.controlViewAppeared = YES;
    [self cancelAutoFadeOutControlView];
    @weakify(self)
    self.afterBlock = dispatch_block_create(0, ^{
        @strongify(self)
        [self hideControlViewWithAnimated:YES];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ZFPlayerAnimationTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(),self.afterBlock);
}

/// 取消延时隐藏controlView的方法
- (void)cancelAutoFadeOutControlView {
    if (self.afterBlock) {
        dispatch_block_cancel(self.afterBlock);
        self.afterBlock = nil;
    }
}

/// 隐藏控制层
- (void)hideControlViewWithAnimated:(BOOL)animated {
    [UIView animateWithDuration:animated?ZFPlayerControlViewAutoFadeOutTimeInterval:0 animations:^{
        //        if (self.player.isFullScreen) {
        //
        //        } else
        {
            [_soundBtn setSelected:self.player.currentPlayerManager.isMuted];
            [_fullScreenBtn setSelected:self.player.isFullScreen];
            [_backBtn setHidden:!_fullScreenBtn.isSelected];
            
            if (!self.player.isSmallFloatViewShow) {
                [self hideControlView];
            }
        }
        self.controlViewAppeared = NO;
    } completion:^(BOOL finished) {
        
    }];
}

/// 显示控制层
- (void)showControlViewWithAnimated:(BOOL)animated  {
    [UIView animateWithDuration:animated?ZFPlayerControlViewAutoFadeOutTimeInterval:0 animations:^{
        //        if (self.player.isFullScreen) {
        //
        //        } else
        {
            [_soundBtn setSelected:self.player.currentPlayerManager.isMuted];
            [_fullScreenBtn setSelected:self.player.isFullScreen];
            [_backBtn setHidden:!_fullScreenBtn.isSelected];
            
            if (!self.player.isSmallFloatViewShow) {
                [self showControlView];
            }
        }
    } completion:^(BOOL finished) {
        [self autoFadeOutControlView];
    }];
}

/// 音量改变的通知
- (void)volumeChanged:(NSNotification *)notification {
    float volume = [[[notification userInfo] objectForKey:@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
    if (self.player.isFullScreen) {
        [self.volumeBrightnessView updateProgress:volume withVolumeBrightnessType:ZFVolumeBrightnessTypeVolume];
    } else {
        [self.volumeBrightnessView addSystemVolumeView];
    }
}

#pragma mark - Public Method

/// 重置控制层
- (void)resetControlView {
    self.bottomToolView.alpha        = 1;
    self.backBtn.alpha               = 1;
    self.slider.value                = 0;
    self.slider.bufferValue          = 0;
    self.currentTimeLabel.text       = @"00:00";
    self.totalTimeLabel.text         = @"00:00";
    self.backgroundColor             = [UIColor clearColor];
    self.playOrPauseBtn.selected     = YES;
    self.centerPlayOrPauseBtn.selected = YES;
    //    self.backBtn.alpha               = 1;
    
    [_ivPlay setHidden:self.playOrPauseBtn.isSelected];
    if (_showBtnMsg) {
        [_btnMsg setHidden:!self.playOrPauseBtn.isSelected];
    }
    
    [_soundBtn setSelected:self.player.currentPlayerManager.isMuted];
    [_fullScreenBtn setSelected:self.player.isFullScreen];
    [_backBtn setHidden:!_fullScreenBtn.isSelected];
    
    self.vFail.hidden = YES;
    
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
}

/// 设置标题、封面、全屏模式
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl fullScreenMode:(ZFFullScreenMode)fullScreenMode {
    [self resetControlView];
    [self layoutIfNeeded];
    [self setNeedsDisplay];
//    [_coverImageView setImageURLString:coverUrl idx:1 def:@"" aDelegate:nil];
    [self showTitle:title fullScreenMode:fullScreenMode];
}

#pragma mark - ZFPlayerControlViewDelegate

/// 手势筛选，返回NO不响应该手势
- (BOOL)gestureTriggerCondition:(ZFPlayerGestureControl *)gestureControl gestureType:(ZFPlayerGestureType)gestureType gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer touch:(nonnull UITouch *)touch {
    CGPoint point = [touch locationInView:self];
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen && gestureType != ZFPlayerGestureTypeSingleTap) {
        return NO;
    }
    if (self.player.isFullScreen) {
        return [self shouldResponseGestureWithPoint:point withGestureType:gestureType touch:touch];
    } else {
        return [self shouldResponseGestureWithPoint:point withGestureType:gestureType touch:touch];
    }
}

/// 单击手势事件
- (void)gestureSingleTapped:(ZFPlayerGestureControl *)gestureControl {
    if (!self.player) return;
    if (self.player.isSmallFloatViewShow && !self.player.isFullScreen) {
        [self.player enterFullScreen:YES animated:YES];
    } else {
        if (self.controlViewAppeared) {
            [self hideControlViewWithAnimated:YES];
        } else {
            [self showControlViewWithAnimated:YES];
        }
    }
}

/// 双击手势事件
- (void)gestureDoubleTapped:(ZFPlayerGestureControl *)gestureControl {
    if (self.player.isFullScreen) {
        
    } else {
        [self playOrPause];
    }
}

/// 开始滑动手势事件
- (void)gestureBeganPan:(ZFPlayerGestureControl *)gestureControl panDirection:(ZFPanDirection)direction panLocation:(ZFPanLocation)location {
    if (direction == ZFPanDirectionH) {
        self.sumTime = self.player.currentTime;
    }
}

/// 滑动中手势事件
- (void)gestureChangedPan:(ZFPlayerGestureControl *)gestureControl panDirection:(ZFPanDirection)direction panLocation:(ZFPanLocation)location withVelocity:(CGPoint)velocity {
    if (direction == ZFPanDirectionH) {
        // 每次滑动需要叠加时间
        self.sumTime += velocity.x / 200;
        // 需要限定sumTime的范围
        NSTimeInterval totalMovieDuration = self.player.totalTime;
        if (totalMovieDuration == 0) return;
        if (self.sumTime > totalMovieDuration) { self.sumTime = totalMovieDuration;}
        if (self.sumTime < 0) { self.sumTime = 0; }
        BOOL style = false;
        if (velocity.x > 0) { style = YES; }
        if (velocity.x < 0) { style = NO; }
        if (velocity.x == 0) { return; }
        [self sliderValueChangingValue:self.sumTime/totalMovieDuration isForward:style];
    } else if (direction == ZFPanDirectionV) {
        if (location == ZFPanLocationLeft) { /// 调节亮度
            self.player.brightness -= (velocity.y) / 10000;
            [self.volumeBrightnessView updateProgress:self.player.brightness withVolumeBrightnessType:ZFVolumeBrightnessTypeumeBrightness];
        } else if (location == ZFPanLocationRight) { /// 调节声音
            self.player.volume -= (velocity.y) / 10000;
            if (self.player.isFullScreen) {
                [self.volumeBrightnessView updateProgress:self.player.volume withVolumeBrightnessType:ZFVolumeBrightnessTypeVolume];
            }
        }
    }
}

/// 滑动结束手势事件
- (void)gestureEndedPan:(ZFPlayerGestureControl *)gestureControl panDirection:(ZFPanDirection)direction panLocation:(ZFPanLocation)location {
    if (direction == ZFPanDirectionH && self.sumTime >= 0 && self.player.totalTime > 0) {
        [self.player seekToTime:self.sumTime completionHandler:nil];
        self.sumTime = 0;
    }
}

/// 捏合手势事件，这里改变了视频的填充模式
- (void)gesturePinched:(ZFPlayerGestureControl *)gestureControl scale:(float)scale {
    if (scale > 1) {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFill;
    } else {
        self.player.currentPlayerManager.scalingMode = ZFPlayerScalingModeAspectFit;
    }
}

/// 准备播放
- (void)videoPlayer:(ZFPlayerController *)videoPlayer prepareToPlay:(NSURL *)assetURL {
    [self hideControlViewWithAnimated:NO];
}

/// 播放状态改变
- (void)videoPlayer:(ZFPlayerController *)videoPlayer playStateChanged:(ZFPlayerPlaybackState)state {
    if (state == ZFPlayerPlayStatePlaying) {
        [self playBtnSelectedState:YES];
        
        self.vFail.hidden = YES;
    } else if (state == ZFPlayerPlayStatePaused) {
        [self playBtnSelectedState:NO];
        
        self.vFail.hidden = YES;
    } else if (state == ZFPlayerPlayStatePlayFailed) {
        self.vFail.hidden = NO;
        [self.activity stopAnimating];
    }
}

/// 加载状态改变
- (void)videoPlayer:(ZFPlayerController *)videoPlayer loadStateChanged:(ZFPlayerLoadState)state {
    if (state == ZFPlayerLoadStatePrepare) {
        [self.coverImageView setAlpha:1.0];
        self.coverImageView.hidden = NO;
    } else if (state == ZFPlayerLoadStatePlaythroughOK) {
        //        self.coverImageView.hidden = YES;
        [self.coverImageView setAlpha:1.0];
        
        [UIView animateWithDuration:0.5
                              delay:0.0
                            options: UIViewAnimationOptionCurveEaseOut
                         animations:^(void) {
                             [self.coverImageView setAlpha:0.0];
                         }
                         completion:^(BOOL finished) {
                             if (finished) {
                                 self.coverImageView.hidden = YES;
                             }
                         }];
    }
    if (state == ZFPlayerLoadStateStalled || state == ZFPlayerLoadStatePrepare) {
        [self.activity startAnimating];
    } else {
        [self.activity stopAnimating];
    }
}

/// 播放进度改变回调
- (void)videoPlayer:(ZFPlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime {
    if (!self.slider.isdragging) {
        NSString *currentTimeString = [ZFUtilities convertTimeSecond:currentTime];
        self.currentTimeLabel.text = currentTimeString;
        NSString *totalTimeString = [ZFUtilities convertTimeSecond:totalTime];
        self.totalTimeLabel.text = totalTimeString;
        self.slider.value = videoPlayer.progress;
    }
}

/// 缓冲改变回调
- (void)videoPlayer:(ZFPlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime {
    self.slider.bufferValue = videoPlayer.bufferProgress;
}

/// 视频view即将旋转
- (void)videoPlayer:(ZFPlayerController *)videoPlayer orientationWillChange:(ZFOrientationObserver *)observer {
    [_soundBtn setSelected:self.player.currentPlayerManager.isMuted];
    [_fullScreenBtn setSelected:observer.isFullScreen];
    [_backBtn setHidden:!_fullScreenBtn.isSelected];
    
    if (videoPlayer.isSmallFloatViewShow) {
        if (observer.isFullScreen) {
            [self cancelAutoFadeOutControlView];
        }
    }
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
    
    if (observer.isFullScreen) {
        [self.volumeBrightnessView removeSystemVolumeView];
    } else {
        [self.volumeBrightnessView addSystemVolumeView];
    }
}

/// 视频view已经旋转
- (void)videoPlayer:(ZFPlayerController *)videoPlayer orientationDidChanged:(ZFOrientationObserver *)observer {
    //    CGFloat fullW = self.bounds.size.width;
    //    CGFloat fullH = self.bounds.size.height;
    //    CGRect subFrame = self.bounds;
    //
    //    [view setFrame:self.bounds];
    //    [view setNeedsLayout];
    //
    //    [_portraitControlView setFrame:self.bounds];
    //    [_portraitControlView setNeedsLayout];
    //
    //    subFrame = _bottomToolView.frame;
    //    subFrame.size.width = fullW;
    //    [_bottomToolView setFrame:subFrame];
    //    [_bottomToolView layoutIfNeeded];
    
    
    if (self.controlViewAppeared) {
        [self showControlViewWithAnimated:NO];
    } else {
        [self hideControlViewWithAnimated:NO];
    }
}

/// 锁定旋转方向
- (void)lockedVideoPlayer:(ZFPlayerController *)videoPlayer lockedScreen:(BOOL)locked {
    [self showControlViewWithAnimated:YES];
}

/// 列表滑动时视频view已经显示
- (void)playerDidAppearInScrollView:(ZFPlayerController *)videoPlayer {
}

/// 列表滑动时视频view已经消失
- (void)playerDidDisappearInScrollView:(ZFPlayerController *)videoPlayer {
}

#pragma mark - Private Method

- (void)sliderValueChangingValue:(CGFloat)value isForward:(BOOL)forward {
}

/// 隐藏快进视图
- (void)hideFastView {
}

/// 加载失败
- (void)failBtnClick:(UIButton *)sender {
    //    [self.player.currentPlayerManager reloadPlayer];
}

#pragma mark - setter

- (void)setPlayer:(ZFPlayerController *)player {
    _player = player;
}

#pragma mark - getter

- (ZFVolumeBrightnessView *)volumeBrightnessView {
    if (!_volumeBrightnessView) {
        _volumeBrightnessView = [[ZFVolumeBrightnessView alloc] init];
    }
    return _volumeBrightnessView;
}






#pragma mark - ZFSliderViewDelegate

- (void)sliderTouchBegan:(float)value {
    self.slider.isdragging = YES;
}

- (void)sliderTouchEnded:(float)value {
    if (self.player.totalTime > 0) {
        @weakify(self)
        [self.player seekToTime:self.player.totalTime*value completionHandler:^(BOOL finished) {
            @strongify(self)
            if (finished) {
                self.slider.isdragging = NO;
                [self.player.currentPlayerManager play];
            }
        }];
    } else {
        self.slider.isdragging = NO;
    }
    if (self.sliderValueChanged) self.sliderValueChanged(value);
}

- (void)sliderValueChanged:(float)value {
    if (self.player.totalTime == 0) {
        self.slider.value = 0;
        return;
    }
    self.slider.isdragging = YES;
    NSString *currentTimeString = [ZFUtilities convertTimeSecond:self.player.totalTime*value];
    self.currentTimeLabel.text = currentTimeString;
    if (self.sliderValueChanging) self.sliderValueChanging(value,self.slider.isForward);
}

- (void)sliderTapped:(float)value {
    if (self.player.totalTime > 0) {
        self.slider.isdragging = YES;
        @weakify(self)
        [self.player seekToTime:self.player.totalTime*value completionHandler:^(BOOL finished) {
            @strongify(self)
            if (finished) {
                self.slider.isdragging = NO;
                [self.player.currentPlayerManager play];
            }
        }];
    } else {
        self.slider.isdragging = NO;
        self.slider.value = 0;
    }
}

#pragma mark - action

- (void)backBtnClickAction:(UIButton *)sender {
    [self.player enterFullScreen:NO animated:YES];
}

- (void)playPauseButtonClickAction:(UIButton *)sender {
    [self playOrPause];
}

- (void)soundButtonClickAction:(UIButton *)sender {
    if (self.player.currentPlayerManager.isMuted) {
        [self.player.currentPlayerManager setMuted:NO];
    }else{
        [self.player.currentPlayerManager setMuted:YES];
    }
    
    [_soundBtn setSelected:self.player.currentPlayerManager.isMuted];
}

- (void)fullScreenButtonClickAction:(UIButton *)sender {
    if (self.player.isFullScreen) {
        [self.player enterFullScreen:NO animated:YES];
    }else{
        [self.player enterFullScreen:YES animated:YES];
    }
}

- (void)play {
    self.playOrPauseBtn.selected = YES;
    self.centerPlayOrPauseBtn.selected = YES;
    [_ivPlay setHidden:self.playOrPauseBtn.isSelected];
    if (_showBtnMsg) {
        [_btnMsg setHidden:!self.playOrPauseBtn.isSelected];
    }
    
    [self.player.currentPlayerManager play];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    
}

- (void)pause {
    self.playOrPauseBtn.selected = NO;
    self.centerPlayOrPauseBtn.selected = NO;
    [self.player.currentPlayerManager pause];
    
    [_ivPlay setHidden:self.playOrPauseBtn.isSelected];
    if (_showBtnMsg) {
        [_btnMsg setHidden:!self.playOrPauseBtn.isSelected];
    }
}

/// 根据当前播放状态取反
- (void)playOrPause {
    
    BOOL isPlay = self.playOrPauseBtn.isSelected;//[[BSGlobalData sharedInstance] isPlayVideoWithOption];
    if (!isPlay) {
        if(_delegate != nil && [_delegate respondsToSelector:@selector(onPlayTouched:)]) {
            [_delegate onPlayTouched:self];
            return;
        }
    }
    
    
    self.playOrPauseBtn.selected = !self.playOrPauseBtn.isSelected;
    self.centerPlayOrPauseBtn.selected = !self.centerPlayOrPauseBtn.isSelected;
    
    self.playOrPauseBtn.isSelected? [self play]: [self pause];
}

- (void)playBtnSelectedState:(BOOL)selected {
    self.playOrPauseBtn.selected = selected;
    [_ivPlay setHidden:self.playOrPauseBtn.isSelected];
    if (_showBtnMsg) {
        [_btnMsg setHidden:!self.playOrPauseBtn.isSelected];
    }
}

#pragma mark -
- (void)showControlView {
    self.bottomToolView.alpha = 1;
    self.backBtn.alpha = 1;
    self.isShow = YES;
    self.bottomToolView.y = _portraitControlView.height - self.bottomToolView.height;
    self.playOrPauseBtn.alpha = 1;
    self.player.statusBarHidden = NO;
    self.centerPlayOrPauseBtn.alpha = 1;
}

- (void)hideControlView {
    self.isShow = NO;
    self.bottomToolView.y = self.height;
    self.playOrPauseBtn.alpha = 0;
    self.player.statusBarHidden = NO;
    self.bottomToolView.alpha = 0;
    self.backBtn.alpha = 0;
    self.centerPlayOrPauseBtn.alpha = 0;
}

- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(ZFPlayerGestureType)type touch:(nonnull UITouch *)touch {
    if (point.y > self.bottomToolView.y || [touch.view isKindOfClass:[UIButton class]]) {
        return NO;
    }
    if (type == ZFPlayerGestureTypePan && self.player.scrollView) {
        return NO;
    }
    return YES;
}

- (void)showTitle:(NSString *)title fullScreenMode:(ZFFullScreenMode)fullScreenMode {
    self.player.orientationObserver.fullScreenMode = fullScreenMode;
}

@end
