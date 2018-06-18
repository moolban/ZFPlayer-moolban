//
//  ZFLandScapeControlView.h
//
// Copyright (c) 2016年 任子丰 ( http://github.com/renzifeng )
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <UIKit/UIKit.h>
#import <ZFPlayer/ZFPlayer.h>
#import "ZFUtilities.h"

@interface ZFLandScapeControlView : UIView

@property (nonatomic, copy, nullable) void(^sliderValueChanging)(CGFloat value,BOOL forward);
@property (nonatomic, copy, nullable) void(^sliderValueChanged)(CGFloat value);

<<<<<<< HEAD:ZFPlayer/ASValuePopUpView.h
@interface ASValuePopUpView : UIView <CAAnimationDelegate>
=======
- (void)resetControlView;
>>>>>>> 3e122018b8f6936d5e9163553b1b5449e1793345:Pretest/Example/ZFPlayer/ControlView/ZFLandScapeControlView.h

- (void)showControlView;

- (void)hideControlView;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer prepareToPlay:(NSURL *)assetURL;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer currentTime:(NSTimeInterval)currentTime totalTime:(NSTimeInterval)totalTime;

- (void)videoPlayer:(ZFPlayerController *)videoPlayer bufferTime:(NSTimeInterval)bufferTime totalTime:(NSTimeInterval)totalTime;

- (BOOL)shouldResponseGestureWithPoint:(CGPoint)point withGestureType:(ZFPlayerGestureType)type touch:(nonnull UITouch *)touch;

- (void)showTitle:(NSString *_Nullable)title fullScreenMode:(ZFFullScreenMode)fullScreenMode;

<<<<<<< HEAD:ZFPlayer/ASValuePopUpView.h
- (void)showAnimated:(BOOL)animated;
- (void)hideAnimated:(BOOL)animated completionBlock:(void (^)(void))block;

=======
/// 根据当前播放状态取反
- (void)playOrPause;

- (void)playBtnSelectedState:(BOOL)selected;

>>>>>>> 3e122018b8f6936d5e9163553b1b5449e1793345:Pretest/Example/ZFPlayer/ControlView/ZFLandScapeControlView.h
@end
