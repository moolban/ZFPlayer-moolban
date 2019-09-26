
//  ZFOrentationObserver.m
//  ZFPlayer
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

#import "ZFOrientationObserver.h"
#import "ZFPlayer.h"

#define SysVersion [[UIDevice currentDevice] systemVersion].floatValue

@interface UIWindow (CurrentViewController)

/*!
 @method currentViewController
 @return Returns the topViewController in stack of topMostController.
 */
+ (UIViewController*)zf_currentViewController;

@end

@implementation UIWindow (CurrentViewController)

+ (UIViewController*)zf_currentViewController; {
    UIWindow *window = [[UIApplication sharedApplication].delegate window];
    UIViewController *topViewController = [window rootViewController];
    while (true) {
        if (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)topViewController topViewController]) {
            topViewController = [(UINavigationController *)topViewController topViewController];
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    return topViewController;
}

@end

@interface ZFOrientationObserver ()

@property (nonatomic, weak) UIView *view;

@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;

@property (nonatomic, strong) UIView *cell;

@property (nonatomic, assign) NSInteger playerViewTag;

@property (nonatomic, assign) ZFRotateType roateType;

@end

@implementation ZFOrientationObserver

- (instancetype)init {
    self = [super init];
    if (self) {
        _duration = 0.25;
        _fullScreenMode = ZFFullScreenModeLandscape;
        _allowOrentitaionRotation = YES;
    }
    return self;
}

- (instancetype)initWithRotateView:(UIView *)rotateView containerView:(UIView *)containerView {
    if ([self init]) {
        _roateType = ZFRotateTypeNormal;
        _view = rotateView;
        _containerView = containerView;
    }
    return self;
}

- (void)cellModelRotateView:(UIView *)rotateView rotateViewAtCell:(UIView *)cell playerViewTag:(NSInteger)playerViewTag {
    self.roateType = ZFRotateTypeCell;
    self.view = rotateView;
    self.cell = cell;
    self.playerViewTag = playerViewTag;
}

- (void)cellSmallModelRotateView:(UIView *)rotateView containerView:(UIView *)containerView {
    self.roateType = ZFRotateTypeCellSmall;
    self.view = rotateView;
    self.containerView = containerView;
}

- (void)dealloc {
    [self removeDeviceOrientationObserver];
}

- (void)addDeviceOrientationObserver {
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)removeDeviceOrientationObserver {
    if (![UIDevice currentDevice].generatesDeviceOrientationNotifications) {
        [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)handleDeviceOrientationChange {
    if (self.fullScreenMode == ZFFullScreenModePortrait || !self.allowOrentitaionRotation) return;
    if (UIDeviceOrientationIsValidInterfaceOrientation([UIDevice currentDevice].orientation)) {
        _currentOrientation = (UIInterfaceOrientation)[UIDevice currentDevice].orientation;
    } else {
        _currentOrientation = UIInterfaceOrientationUnknown;
        return;
    }
    
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
    // Determine that if the current direction is the same as the direction you want to rotate, do nothing
    if (_currentOrientation == currentOrientation && ![self isNeedAdaptiveiOS8Rotation]) return;
    
    switch (_currentOrientation) {
        case UIInterfaceOrientationPortrait: {
            [self enterLandscapeFullScreen:UIInterfaceOrientationPortrait animated:YES];
        }
            break;
        case UIInterfaceOrientationLandscapeLeft: {
            [self enterLandscapeFullScreen:UIInterfaceOrientationLandscapeLeft animated:YES];
        }
            break;
        case UIInterfaceOrientationLandscapeRight: {
            [self enterLandscapeFullScreen:UIInterfaceOrientationLandscapeRight animated:YES];
        }
            break;
        default: break;
    }
}

- (void)enterLandscapeFullScreen:(UIInterfaceOrientation)orientation animated:(BOOL)animated {
    if (self.fullScreenMode == ZFFullScreenModePortrait) return;

    _currentOrientation = orientation;
    UIView *superview = nil;
    CGRect frame;

    if (!self.isFullScreen) {
        superview = self.fullScreenContainerView;
        if (!self.isFullScreen) { /// It's not set from the other side of the screen to this side
            self.view.frame = [self.view convertRect:self.view.frame toView:superview];
        }
        self.fullScreen = YES;
        /// 先加到window上，效果更好一些
        [self.view removeFromSuperview];
        [superview addSubview:_view];
        [self setConstraint:superview childView:self.view isLandscape:UIInterfaceOrientationIsLandscape(orientation)];
    } else {
        if (self.roateType == ZFRotateTypeCell) superview = [self.cell viewWithTag:self.playerViewTag];
        else superview = self.containerView;
        self.fullScreen = NO;
    }
    frame = [superview convertRect:superview.bounds toView:self.fullScreenContainerView];
//    [UIApplication sharedApplication].statusBarOrientation = orientation;
    
    /// 处理8.0系统键盘
    if (SysVersion >= 8.0 && SysVersion < 9.0) {
        NSInteger windowCount = [[[UIApplication sharedApplication] windows] count];
        if(windowCount > 1) {
            UIWindow *keyboardWindow = [[[UIApplication sharedApplication] windows] objectAtIndex:(windowCount-1)];
            if (UIInterfaceOrientationIsLandscape(orientation)) {
                keyboardWindow.bounds = CGRectMake(0, 0, MAX(ZFPlayerScreenHeight, ZFPlayerScreenWidth), MIN(ZFPlayerScreenHeight, ZFPlayerScreenWidth));
            } else {
                keyboardWindow.bounds = CGRectMake(0, 0, MIN(ZFPlayerScreenHeight, ZFPlayerScreenWidth), MAX(ZFPlayerScreenHeight, ZFPlayerScreenWidth));
            }
            keyboardWindow.transform = [self getTransformRotationAngle:orientation];
        }
    }
    
    if (self.orientationWillChange)
        self.orientationWillChange(self, self.isFullScreen);
  
    CGFloat padding = 0;
    CGFloat centerYPosition = 0;
    if (@available(iOS 11.0, *)) {
      UIWindow *window = UIApplication.sharedApplication.keyWindow;
      if (UIInterfaceOrientationIsLandscape(orientation) && window.safeAreaInsets.bottom > 0) {
          padding = window.safeAreaInsets.top + window.safeAreaInsets.bottom;
          centerYPosition = window.safeAreaInsets.top - window.safeAreaInsets.bottom;
          centerYPosition = (centerYPosition > 0 ) ? centerYPosition-10:0;
      }
    }
    
    NSLayoutConstraint *width = [self findViewHeightConstraint:self.view identifier:@"width"];
    NSLayoutConstraint *height = [self findViewHeightConstraint:self.view identifier:@"height"];
    NSLayoutConstraint *centerY = [self findViewHeightConstraint:self.view identifier:@"centerY"];

    if (UIInterfaceOrientationIsLandscape(orientation)) {
        [width setConstant:frame.size.height-padding];
        [height setConstant:frame.size.width];
        [centerY setConstant:centerYPosition];
    } else {
        [width setConstant:frame.size.width];
        [height setConstant:frame.size.height];
        [centerY setConstant:0];
    }

    [UIView animateWithDuration:animated?self.duration:0 animations:^{
        self.view.transform = [self getTransformRotationAngle:orientation];
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [superview addSubview:self.view];
        [self setConstraint:superview childView:self.view isLandscape:UIInterfaceOrientationIsLandscape(orientation)];
        if (self.orientationDidChanged) self.orientationDidChanged(self, self.isFullScreen);
    }];
}

- (void)setConstraint:(UIView *)parentView childView:(UIView *)childView isLandscape:(BOOL)isLandScape{
    childView.translatesAutoresizingMaskIntoConstraints = NO;
    
    CGFloat padding = 0;
    CGFloat centerYPosition = 0;
    if (@available(iOS 11.0, *)) {
      UIWindow *window = UIApplication.sharedApplication.keyWindow;
      if (isLandScape) {
          padding = window.safeAreaInsets.top + window.safeAreaInsets.bottom;
          centerYPosition = window.safeAreaInsets.top - window.safeAreaInsets.bottom;
          centerYPosition = (centerYPosition > 0 ) ? centerYPosition-10:0;
      }
        NSLog(@"window.safeAreaInsets.top %lf", window.safeAreaInsets.top);
        NSLog(@"window.safeAreaInsets.bottom %lf", window.safeAreaInsets.bottom);
    }
    
    CGFloat width = (isLandScape) ? parentView.frame.size.height : parentView.frame.size.width;
    CGFloat height = (isLandScape) ? parentView.frame.size.width : parentView.frame.size.height;

    width -= padding;

    NSLayoutConstraint *viewWidth = [self findViewHeightConstraint:self.view identifier:@"width"];
    
    if ( viewWidth == nil) {
        NSLayoutConstraint *viewWidth =  [NSLayoutConstraint constraintWithItem:childView
                                                                      attribute:NSLayoutAttributeWidth
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:NSLayoutAttributeWidth
                                                                     multiplier:1
                                                                       constant:width];
        viewWidth.identifier = @"width";
        [childView addConstraint:viewWidth];
    } else {
        [viewWidth setConstant:width];
    }
    
    NSLayoutConstraint *viewHeight = [self findViewHeightConstraint:self.view identifier:@"height"];
    if (viewHeight == nil) {
        viewHeight =  [NSLayoutConstraint constraintWithItem:childView
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:NSLayoutAttributeHeight
                                                  multiplier:1
                                                    constant:height];
        viewHeight.identifier = @"height";
        [childView addConstraint:viewHeight];
    } else {
        [viewHeight setConstant:height];
    }

    NSLayoutConstraint *centerX = [self findViewHeightConstraint:parentView identifier:@"centerX"];
    
    if (centerX == nil) {
        centerX = [NSLayoutConstraint constraintWithItem:childView
                                              attribute:NSLayoutAttributeCenterX
                                              relatedBy:NSLayoutRelationEqual
                                                 toItem:parentView
                                              attribute:NSLayoutAttributeCenterX
                                             multiplier:1
                                               constant:0];
        centerX.identifier = @"centerX";
        [parentView addConstraint:centerX];
    }
   
    
    NSLayoutConstraint *centerY = [self findViewHeightConstraint:parentView identifier:@"centerY"];
    if (centerY == nil) {
        centerY = [NSLayoutConstraint constraintWithItem:childView
                                  attribute:NSLayoutAttributeCenterY
                                  relatedBy:NSLayoutRelationEqual
                                     toItem:parentView
                                  attribute:NSLayoutAttributeCenterY
                                 multiplier:1
                                   constant:centerYPosition];
        centerY.identifier = @"centerY";
        [parentView addConstraint:centerY];
    } else {
        [centerY setConstant:centerYPosition];
    }
    
}

- (NSLayoutConstraint *) findViewHeightConstraint:(UIView *)view identifier:(NSString *)identifier{
    NSLayoutConstraint *findConstraint = nil;
    for(NSLayoutConstraint *cons in view.constraints)   {
        if ([cons.identifier isEqualToString:identifier]) {
            findConstraint = cons;
            break;
        }
    }
    return findConstraint;
}


- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = (int)orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

- (BOOL)isNeedAdaptiveiOS8Rotation {
    NSArray<NSString *> *versionStrArr = [[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."];
    int firstVer = [[versionStrArr objectAtIndex:0] intValue];
    int secondVer = [[versionStrArr objectAtIndex:1] intValue];
    if (firstVer == 8) {
        if (secondVer >= 1 && secondVer <= 3) {
            return YES;
        }
    }
    return NO;
}

/// Gets the rotation Angle of the transformation.
- (CGAffineTransform)getTransformRotationAngle:(UIInterfaceOrientation)orientation {
    if (UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    }
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft){
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if(orientation == UIInterfaceOrientationLandscapeRight){
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

- (void)enterPortraitFullScreen:(BOOL)fullScreen animated:(BOOL)animated {
    if (self.fullScreenMode == ZFFullScreenModeLandscape) return;
    UIView *superview = nil;
    if (fullScreen) {
        superview = self.fullScreenContainerView;
        [superview addSubview:self.view];
        [self setConstraint:superview childView:self.view isLandscape:NO];
        self.fullScreen = YES;
    } else {
        if (self.roateType == ZFRotateTypeCell) {
            superview = [self.cell viewWithTag:self.playerViewTag];
        } else {
            superview = self.containerView;
        }
        self.fullScreen = NO;
    }
    if (self.orientationWillChange) self.orientationWillChange(self, self.isFullScreen);
    
    CGRect frame = [superview convertRect:superview.bounds toView:self.fullScreenContainerView];
    NSLayoutConstraint *width = [self findViewHeightConstraint:self.view identifier:@"width"];
    NSLayoutConstraint *height = [self findViewHeightConstraint:self.view identifier:@"height"];
    [width setConstant:frame.size.width];
    [height setConstant:frame.size.height];
    [UIView animateWithDuration:animated?self.duration:0 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [superview addSubview:self.view];
        [self setConstraint:superview childView:self.view isLandscape:NO];
        if (self.orientationDidChanged) self.orientationDidChanged(self, self.isFullScreen);
    }];
}

- (void)exitFullScreenWithAnimated:(BOOL)animated {
    if (self.fullScreenMode == ZFFullScreenModeLandscape) {
        [self enterLandscapeFullScreen:UIInterfaceOrientationPortrait animated:animated];
    } else if (self.fullScreenMode == ZFFullScreenModePortrait) {
        [self enterPortraitFullScreen:NO animated:animated];
    }
}

- (void)setLockedScreen:(BOOL)lockedScreen {
    _lockedScreen = lockedScreen;
    if (lockedScreen) {
        [self removeDeviceOrientationObserver];
    } else {
        [self addDeviceOrientationObserver];
    }
}

- (UIView *)fullScreenContainerView {
    if (!_fullScreenContainerView) {
        _fullScreenContainerView = [UIApplication sharedApplication].keyWindow;
    }
    return _fullScreenContainerView;
}

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    [[UIWindow zf_currentViewController] setNeedsStatusBarAppearanceUpdate];
}

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    _statusBarHidden = statusBarHidden;
    [[UIWindow zf_currentViewController] setNeedsStatusBarAppearanceUpdate];
}

@end

