//
//  ViewVideoPlayerControler.h
//  ZFPlayer_Example
//
//  Created by WonSang Ryu on 2018. 7. 27..
//  Copyright © 2018년 紫枫. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ZFPortraitControlView.h"

#import "ZFPlayerMediaControl.h"
#import "ZFSpeedLoadingView.h"

@interface ViewVideoPlayerControler : UIView <ZFPlayerMediaControl>
// 동영상 여부 표시(정지일때만 표시)
@property (weak, nonatomic) IBOutlet UIImageView *ivPlay;
/// 加载loading
@property (nonatomic, retain) IBOutlet ZFSpeedLoadingView *activity;
/// 加载失败按钮
@property (nonatomic, retain) IBOutlet UIView *vFail;
@property (nonatomic, retain) IBOutlet UIButton *failBtn;
/// 封面图
@property (nonatomic, retain) IBOutlet UIImageView *coverImageView;

/// 设置标题、封面、全屏模式
- (void)showTitle:(NSString *)title coverURLString:(NSString *)coverUrl fullScreenMode:(ZFFullScreenMode)fullScreenMode;
/// 重置控制层
- (void)resetControlView;



@property (nonatomic, retain) IBOutlet UIView *portraitControlView;
/// 返回按钮
@property (nonatomic, retain) IBOutlet UIButton *backBtn;
/// 底部工具栏
@property (nonatomic, retain) IBOutlet UIView *bottomToolView;
/// 播放或暂停按钮
@property (nonatomic, retain) IBOutlet UIButton *playOrPauseBtn;
/// 播放的当前时间
@property (nonatomic, retain) IBOutlet UILabel *currentTimeLabel;
/// 滑杆
@property (nonatomic, retain) IBOutlet ZFSliderView *slider;
/// 视频总时间
@property (nonatomic, retain) IBOutlet UILabel *totalTimeLabel;

@property (retain, nonatomic) IBOutlet UIButton *soundBtn;
/// 全屏按钮
@property (nonatomic, retain) IBOutlet UIButton *fullScreenBtn;
/// 播放器
@property (nonatomic, weak) ZFPlayerController *player;
/// slider滑动中
@property (nonatomic, copy, nullable) void(^sliderValueChanging)(CGFloat value,BOOL forward);
/// slider滑动结束
@property (nonatomic, copy, nullable) void(^sliderValueChanged)(CGFloat value);

/// 显示控制层
- (void)showControlView;
/// 隐藏控制层
- (void)hideControlView;

/// 是否响应该手势
- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(ZFPlayerGestureType)type touch:(nonnull UITouch *)touch;
/// 标题和全屏模式
- (void)showTitle:(NSString *_Nullable)title fullScreenMode:(ZFFullScreenMode)fullScreenMode;
/// 根据当前播放状态取反
- (void)playOrPause;
/// 播放按钮状态
- (void)playBtnSelectedState:(BOOL)selected;

- (void)play;
- (void)pause;
@end
