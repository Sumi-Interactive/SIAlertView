//
//  SIAlertView.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertView.h"
#import "UIWindow+SIUtils.h"
#import <QuartzCore/QuartzCore.h>

NSString *const SIAlertViewWillShowNotification = @"SIAlertViewWillShowNotification";
NSString *const SIAlertViewDidShowNotification = @"SIAlertViewDidShowNotification";
NSString *const SIAlertViewWillDismissNotification = @"SIAlertViewWillDismissNotification";
NSString *const SIAlertViewDidDismissNotification = @"SIAlertViewDidDismissNotification";

#define DEBUG_LAYOUT 0

#define GAP 10
#define CONTENT_PADDING_LEFT 15
#define CONTENT_PADDING_TOP 20
#define BUTTON_HEIGHT 50
#define CONTAINER_WIDTH 270

const UIWindowLevel UIWindowLevelSIAlert = 1999.0;  // don't overlap system's alert
const UIWindowLevel UIWindowLevelSIAlertBackground = 1998.0; // below the alert window

@class SIAlertBackgroundWindow;

static NSMutableArray *__si_alert_queue;
static BOOL __si_alert_animating;
static SIAlertBackgroundWindow *__si_alert_background_window;
static SIAlertView *__si_alert_current_view;

@interface SIAlertView ()

@property (nonatomic, strong) NSMutableArray *items;
@property (nonatomic, weak) UIWindow *oldKeyWindow;
@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, assign) UIViewTintAdjustmentMode oldTintAdjustmentMode;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *wrapperView;
@property (nonatomic, strong) UIScrollView *contentContainerView;
@property (nonatomic, strong) UIView *buttonContainerView;
@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, strong) CAShapeLayer *lineLayer;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, assign, getter = isLayoutDirty) BOOL layoutDirty;

+ (NSMutableArray *)sharedQueue;
+ (SIAlertView *)currentAlertView;

+ (BOOL)isAnimating;
+ (void)setAnimating:(BOOL)animating;

+ (void)showBackground;
+ (void)hideBackgroundAnimated:(BOOL)animated;

- (void)setup;
- (void)invalidateLayout;
- (void)resetTransition;

@end

#pragma mark - SIBackgroundWindow

@interface SIAlertBackgroundWindow : UIWindow

@end

@interface SIAlertBackgroundWindow ()

@property (nonatomic, assign) SIAlertViewBackgroundStyle style;

@end

@implementation SIAlertBackgroundWindow

- (id)initWithFrame:(CGRect)frame andStyle:(SIAlertViewBackgroundStyle)style
{
    self = [super initWithFrame:frame];
    if (self) {
        self.style = style;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelSIAlertBackground;
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    switch (self.style) {
        case SIAlertViewBackgroundStyleGradient:
        {
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
            break;
        }
        case SIAlertViewBackgroundStyleSolid:
        {
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);
            break;
        }
    }
}

@end

#pragma mark - SIAlertItem

@interface SIAlertItem : NSObject

@property (nonatomic, copy) NSAttributedString *attributedTitle;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, copy) SIAlertViewHandler action;

@end

@implementation SIAlertItem

@end

#pragma mark - SIAlertViewController

@interface SIAlertViewController : UIViewController

@property (nonatomic, strong) SIAlertView *alertView;

@end

@implementation SIAlertViewController

#pragma mark - View life cycle

- (void)loadView
{
    self.view = self.alertView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.alertView setup];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self.alertView resetTransition];
    [self.alertView invalidateLayout];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (NSUInteger)supportedInterfaceOrientations
{
    UIViewController *viewController = [self.alertView.oldKeyWindow currentViewController];
    if (viewController) {
        return [viewController supportedInterfaceOrientations];
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    UIViewController *viewController = [self.alertView.oldKeyWindow currentViewController];
    if (viewController) {
        return [viewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    }
    return YES;
}

- (BOOL)shouldAutorotate
{
    UIViewController *viewController = [self.alertView.oldKeyWindow currentViewController];
    if (viewController) {
        return [viewController shouldAutorotate];
    }
    return YES;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    UIWindow *window = self.alertView.oldKeyWindow;
    if (!window) {
        window = [UIApplication sharedApplication].windows[0];
    }
    return [[window viewControllerForStatusBarStyle] preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    UIWindow *window = self.alertView.oldKeyWindow;
    if (!window) {
        window = [UIApplication sharedApplication].windows[0];
    }
    return [[window viewControllerForStatusBarHidden] prefersStatusBarHidden];
}

@end

#pragma mark - SIAlertView

@implementation SIAlertView

+ (void)initialize
{
    if (self != [SIAlertView class])
        return;
    
    SIAlertView *appearance = [self appearance];
    appearance.viewBackgroundColor = [UIColor whiteColor];
    appearance.seperatorColor = [UIColor colorWithWhite:0 alpha:0.15];
    appearance.cornerRadius = 2;
    appearance.defaultButtonBackgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
    appearance.cancelButtonBackgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
    appearance.destructiveButtonBackgroundColor = [UIColor colorWithWhite:0.96 alpha:1];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
	self = [super init];
	if (self) {
        if (title) {
            _attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:[SIAlertView defaultTitleAttributes]];
        }
        if (message) {
            _attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:[SIAlertView defaultMessageAttributes]];
        }
        
		self.items = [NSMutableArray array];
	}
	return self;
}

- (id)initWithAttributedTitle:(NSAttributedString *)attributedTitle attributedMessage:(NSAttributedString *)attributedMessage
{
	self = [super init];
	if (self) {
		_attributedTitle = [attributedTitle copy];
        _attributedMessage = [attributedMessage copy];
		self.items = [NSMutableArray array];
	}
	return self;
}

#pragma mark - Class methods

+ (NSMutableArray *)sharedQueue
{
    if (!__si_alert_queue) {
        __si_alert_queue = [NSMutableArray array];
    }
    return __si_alert_queue;
}

+ (SIAlertView *)currentAlertView
{
    return __si_alert_current_view;
}

+ (void)setCurrentAlertView:(SIAlertView *)alertView
{
    __si_alert_current_view = alertView;
}

+ (BOOL)isAnimating
{
    return __si_alert_animating;
}

+ (void)setAnimating:(BOOL)animating
{
    __si_alert_animating = animating;
}

+ (void)showBackground
{
    if (!__si_alert_background_window) {
        __si_alert_background_window = [[SIAlertBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                                             andStyle:[SIAlertView currentAlertView].backgroundStyle];
        [__si_alert_background_window makeKeyAndVisible];
        __si_alert_background_window.alpha = 0;
        [UIView animateWithDuration:0.3
                         animations:^{
                             __si_alert_background_window.alpha = 1;
                         }];
    }
}

+ (void)hideBackgroundAnimated:(BOOL)animated
{
    if (!animated) {
        [__si_alert_background_window removeFromSuperview];
        __si_alert_background_window = nil;
        return;
    }
    [UIView animateWithDuration:0.3
                     animations:^{
                         __si_alert_background_window.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [__si_alert_background_window removeFromSuperview];
                         __si_alert_background_window = nil;
                     }];
}

#pragma mark - Style

+ (NSDictionary *)defaultTitleAttributes
{
    UIFont *font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.1;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle};
    return attributes;
}

+ (NSDictionary *)defaultMessageAttributes
{
    UIFont *font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineHeightMultiple = 1.1;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    NSDictionary *attributes = @{NSFontAttributeName : font, NSParagraphStyleAttributeName : paragraphStyle};
    return attributes;
}

+ (NSDictionary *)defaultButtonAttributesForType:(SIAlertViewButtonType)type
{
    NSDictionary *attributes = @{NSFontAttributeName : type == SIAlertViewButtonTypeDefault ? [UIFont systemFontOfSize:[UIFont buttonFontSize]] : [UIFont boldSystemFontOfSize:[UIFont buttonFontSize]]};
    if (type == SIAlertViewButtonTypeDestructive) {
        NSMutableDictionary *dictionary = [attributes mutableCopy];
        [dictionary setObject:[UIColor redColor] forKey:NSForegroundColorAttributeName];
        attributes = [dictionary copy];
    }
    return attributes;
}

#pragma mark - Setters & Getters

- (void)setTitle:(NSString *)title
{
    if (title) {
        NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:[SIAlertView defaultTitleAttributes]];
        [self setAttributedTitle:attributedTitle];
    } else {
        [self setAttributedTitle:nil];
    }
}

- (void)setMessage:(NSString *)message
{
    if (message) {
        NSAttributedString *attributedMessage = [[NSAttributedString alloc] initWithString:message attributes:[SIAlertView defaultMessageAttributes]];
        [self setAttributedMessage:attributedMessage];
    } else {
        [self setAttributedMessage:nil];
    }
}

- (NSString *)title
{
    return self.attributedTitle.string;
}

- (NSString *)message
{
    return self.attributedMessage.string;
}

- (void)setAttributedTitle:(NSAttributedString *)attributedTitle
{
    _attributedTitle = [attributedTitle copy];
    [self updateTitleLabel];
}

- (void)setAttributedMessage:(NSAttributedString *)attributedMessage
{
    _attributedMessage = [attributedMessage copy];
    [self updateMessageLabel];
}

#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler
{
    NSAttributedString *attributedTitle = [[NSAttributedString alloc] initWithString:title attributes:[SIAlertView defaultButtonAttributesForType:type]];
    [self addButtonWithAttributedTitle:attributedTitle type:type handler:handler];
}

- (void)addButtonWithAttributedTitle:(NSAttributedString *)attributedTitle type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler
{
    SIAlertItem *item = [[SIAlertItem alloc] init];
	item.attributedTitle = attributedTitle;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
}

- (void)show
{
    if (self.isVisible) {
        return;
    }
    
    self.oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
    
    self.oldTintAdjustmentMode = self.oldKeyWindow.tintAdjustmentMode;
    self.oldKeyWindow.tintAdjustmentMode = UIViewTintAdjustmentModeDimmed;

    if (![[SIAlertView sharedQueue] containsObject:self]) {
        [[SIAlertView sharedQueue] addObject:self];
    }
    
    if ([SIAlertView isAnimating]) {
        return; // wait for next turn
    }
    
    if ([SIAlertView currentAlertView].isVisible) {
        SIAlertView *alert = [SIAlertView currentAlertView];
        [alert dismissAnimated:YES cleanup:NO];
        return;
    }
    
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillShowNotification object:self userInfo:nil];
    
    self.visible = YES;
    
    [SIAlertView setAnimating:YES];
    [SIAlertView setCurrentAlertView:self];
    
    // transition background
    [SIAlertView showBackground];
    
    SIAlertViewController *viewController = [[SIAlertViewController alloc] initWithNibName:nil bundle:nil];
    viewController.alertView = self;
    
    if (!self.alertWindow) {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel = UIWindowLevelSIAlert;
        window.rootViewController = viewController;
        self.alertWindow = window;
    }
    [self.alertWindow makeKeyAndVisible];
    
    [self validateLayout];
    
    [self transitionInCompletion:^{
        if (self.didShowHandler) {
            self.didShowHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewDidShowNotification object:self userInfo:nil];
        
        [SIAlertView setAnimating:NO];
        
        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index < [SIAlertView sharedQueue].count - 1) {
            [self dismissAnimated:YES cleanup:NO]; // dismiss to show next alert view
        }
    }];
}

- (void)dismissAnimated:(BOOL)animated
{
    [self dismissAnimated:animated cleanup:YES];
}

- (void)dismissAnimated:(BOOL)animated cleanup:(BOOL)cleanup
{
    BOOL isVisible = self.isVisible;
    
    if (isVisible) {
        if (self.willDismissHandler) {
            self.willDismissHandler(self);
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillDismissNotification object:self userInfo:nil];
    }
    
    void (^dismissComplete)(void) = ^{
        self.visible = NO;
        
        [self teardown];
        
        [SIAlertView setCurrentAlertView:nil];
        
        SIAlertView *nextAlertView;
        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index != NSNotFound && index < [SIAlertView sharedQueue].count - 1) {
            nextAlertView = [SIAlertView sharedQueue][index + 1];
        }
        
        if (cleanup) {
            [[SIAlertView sharedQueue] removeObject:self];
        }
        
        [SIAlertView setAnimating:NO];
        
        if (isVisible) {
            if (self.didDismissHandler) {
                self.didDismissHandler(self);
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewDidDismissNotification object:self userInfo:nil];
        }
        
        // check if we should show next alert
        if (!isVisible) {
            return;
        }
        
        if (nextAlertView) {
            [nextAlertView show];
        } else {
            // show last alert view
            if ([SIAlertView sharedQueue].count > 0) {
                SIAlertView *alert = [[SIAlertView sharedQueue] lastObject];
                [alert show];
            }
        }
    };
    
    if (animated && isVisible) {
        [SIAlertView setAnimating:YES];
        [self transitionOutCompletion:dismissComplete];
        
        if ([SIAlertView sharedQueue].count == 1) {
            [SIAlertView hideBackgroundAnimated:YES];
        }
        
    } else {
        dismissComplete();
        
        if ([SIAlertView sharedQueue].count == 0) {
            [SIAlertView hideBackgroundAnimated:YES];
        }
    }
    
    UIWindow *window = self.oldKeyWindow;
    window.tintAdjustmentMode = self.oldTintAdjustmentMode;
    if (!window) {
        window = [UIApplication sharedApplication].windows[0];
    }
    [window makeKeyWindow];
    window.hidden = NO;
}

#pragma mark - Transitions

- (void)transitionInCompletion:(void(^)(void))completion
{
    switch (self.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = self.bounds.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleSlideFromTop:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = -rect.size.height;
            self.containerView.frame = rect;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.frame = originalRect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleFade:
        {
            self.containerView.alpha = 0;
            [UIView animateWithDuration:0.3
                             animations:^{
                                 self.containerView.alpha = 1;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(0.01), @(1.2), @(0.9), @(1)];
            animation.keyTimes = @[@(0), @(0.4), @(0.6), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.5;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bouce"];
        }
            break;
        case SIAlertViewTransitionStyleDropDown:
        {
            CGFloat y = self.containerView.center.y;
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
            animation.values = @[@(y - self.bounds.size.height), @(y + 20), @(y - 10), @(y)];
            animation.keyTimes = @[@(0), @(0.5), @(0.75), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.4;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"dropdown"];
        }
            break;
        default:
            break;
    }
}

- (void)transitionOutCompletion:(void(^)(void))completion
{
    switch (self.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = self.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleSlideFromTop:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = -rect.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.frame = rect;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleFade:
        {
            [UIView animateWithDuration:0.25
                             animations:^{
                                 self.containerView.alpha = 0;
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        case SIAlertViewTransitionStyleBounce:
        {
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(1), @(1.2), @(0.01)];
            animation.keyTimes = @[@(0), @(0.4), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.35;
            animation.delegate = self;
            [animation setValue:completion forKey:@"handler"];
            [self.containerView.layer addAnimation:animation forKey:@"bounce"];
            
            self.containerView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
            break;
        case SIAlertViewTransitionStyleDropDown:
        {
            CGPoint point = self.containerView.center;
            point.y += self.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.center = point;
                                 CGFloat angle = ((CGFloat)arc4random_uniform(100) - 50.f) / 100.f;
                                 self.containerView.transform = CGAffineTransformMakeRotation(angle);
                             }
                             completion:^(BOOL finished) {
                                 if (completion) {
                                     completion();
                                 }
                             }];
        }
            break;
        default:
            break;
    }
}

- (void)resetTransition
{
    [self.containerView.layer removeAllAnimations];
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self validateLayout];
}

- (void)invalidateLayout
{
    self.layoutDirty = YES;
    [self setNeedsLayout];
}

- (void)validateLayout
{
    if (!self.isLayoutDirty) {
        return;
    }
    self.layoutDirty = NO;
#if DEBUG_LAYOUT
    NSLog(@"%@, %@", self, NSStringFromSelector(_cmd));
#endif
    
    CGFloat contentContainerViewHeight = 0;
    CGFloat buttonContainerViewHeight = 0;
    
    CGFloat y = CONTENT_PADDING_TOP;
	if (self.titleLabel) {
        self.titleLabel.attributedText = self.attributedTitle;
        CGFloat height = [self heightForTitleLabel];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, height);
        y += height;
	}
    if (self.messageLabel) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        self.messageLabel.attributedText = self.attributedMessage;
        CGFloat height = [self heightForMessageLabel];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, height);
        y += height + GAP;
    }
    contentContainerViewHeight = y;
    
    if (self.items.count > 0) {
        CGMutablePathRef path = CGPathCreateMutable();
        
        CGFloat y = 0;
        if (self.items.count == 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            CGFloat width = CONTAINER_WIDTH * 0.5;
            UIButton *button = self.buttons[0];
            button.frame = CGRectMake(0, y, width, BUTTON_HEIGHT);
            button = self.buttons[1];
            button.frame = CGRectMake(0 + width, y, width, BUTTON_HEIGHT);
            CGPathMoveToPoint(path, NULL, 0, y);
            CGPathAddLineToPoint(path, NULL, CONTAINER_WIDTH, y);
            CGPathMoveToPoint(path, NULL, width, y);
            CGPathAddLineToPoint(path, NULL, width, y + BUTTON_HEIGHT);
            y += BUTTON_HEIGHT;
        } else {
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.frame = CGRectMake(0, y, CONTAINER_WIDTH, BUTTON_HEIGHT);
                CGPathMoveToPoint(path, NULL, 0, y);
                CGPathAddLineToPoint(path, NULL, CONTAINER_WIDTH, y);
                y += BUTTON_HEIGHT;
            }
        }
        self.lineLayer.path = path;
        CGPathRelease(path);
        
        buttonContainerViewHeight = y;
    }
    
    self.contentContainerView.contentSize = CGSizeMake(CONTAINER_WIDTH, contentContainerViewHeight);
    
    CGFloat availableContentContainerViewHeight = self.bounds.size.height - buttonContainerViewHeight - 10;
    if (buttonContainerViewHeight > 0) {
        availableContentContainerViewHeight -= GAP;
    }
    contentContainerViewHeight = MIN(contentContainerViewHeight, MAX(availableContentContainerViewHeight, 0));
    self.contentContainerView.frame = CGRectMake(0, 0, CONTAINER_WIDTH, contentContainerViewHeight);
    
    CGFloat finalHeight = contentContainerViewHeight;
    
    if (buttonContainerViewHeight > 0) {
        self.buttonContainerView.frame = CGRectMake(0, contentContainerViewHeight + GAP, CONTAINER_WIDTH, buttonContainerViewHeight);
        finalHeight += GAP + buttonContainerViewHeight;
    }
    
    CGFloat left = (self.bounds.size.width - CONTAINER_WIDTH) * 0.5;
    CGFloat top = (self.bounds.size.height - finalHeight) * 0.5;
    self.containerView.transform = CGAffineTransformIdentity;
    self.containerView.frame = CGRectMake(left, top, CONTAINER_WIDTH, finalHeight);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;
}

- (CGFloat)heightForTitleLabel
{
    if (self.titleLabel) {
        CGRect rect = [self.attributedTitle boundingRectWithSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, CGFLOAT_MAX)
                                                         options:NSStringDrawingUsesLineFragmentOrigin
                                                         context:nil];
        return ceil(rect.size.height);
    }
    return 0;
}

- (CGFloat)heightForMessageLabel
{
    if (self.messageLabel) {
        CGRect rect = [self.attributedMessage boundingRectWithSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, CGFLOAT_MAX)
                                                           options:NSStringDrawingUsesLineFragmentOrigin
                                                           context:nil];
        return ceil(rect.size.height);
    }
    return 0;
}

#pragma mark - Setup

- (void)setup
{
    [self setupViewHierarchy];
    [self updateTitleLabel];
    [self updateMessageLabel];
    [self setupButtons];
    [self setupLineLayer];
}

- (void)teardown
{
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    self.titleLabel = nil;
    self.messageLabel = nil;
    [self.buttons removeAllObjects];
    [self.alertWindow removeFromSuperview];
    self.alertWindow = nil;
    self.layoutDirty = NO;
}

- (void)setupViewHierarchy
{
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowRadius = self.shadowRadius;
    self.containerView.layer.shadowOpacity = self.shadowRadius > 0 ? 0.5 : 0;
    [self addSubview:self.containerView];
    
    self.wrapperView = [[UIView alloc] initWithFrame:self.bounds];
    self.wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.wrapperView.autoresizesSubviews = NO;
    self.wrapperView.backgroundColor = self.viewBackgroundColor;
    self.wrapperView.layer.cornerRadius = self.cornerRadius;
    self.wrapperView.clipsToBounds = YES;
    [self.containerView addSubview:self.wrapperView];
    
    self.contentContainerView = [[UIScrollView alloc] initWithFrame:self.bounds];
    self.contentContainerView.autoresizesSubviews = NO;
//    self.contentContainerView.backgroundColor = [UIColor clearColor];
    [self.wrapperView addSubview:self.contentContainerView];
    
    self.buttonContainerView = [[UIView alloc] initWithFrame:self.bounds];
    self.buttonContainerView.autoresizesSubviews = NO;
    [self.wrapperView addSubview:self.buttonContainerView];
}

- (void)setupLineLayer
{
    self.lineLayer = [CAShapeLayer layer];
    self.lineLayer.strokeColor = self.seperatorColor.CGColor;
    self.lineLayer.lineWidth = 1 / [UIScreen mainScreen].scale;

    [self.buttonContainerView.layer addSublayer:self.lineLayer];
}

- (void)updateTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.titleLabel.backgroundColor = [UIColor clearColor];
            self.titleLabel.numberOfLines = 0;
			[self.contentContainerView addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
		}
		self.titleLabel.attributedText = self.attributedTitle;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
    [self invalidateLayout];
}

- (void)updateMessageLabel
{
    if (self.message) {
        if (!self.messageLabel) {
            self.messageLabel = [[UILabel alloc] initWithFrame:self.bounds];
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.numberOfLines = 0;
            [self.contentContainerView addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageLabel.attributedText = self.attributedMessage;
    } else {
        [self.messageLabel removeFromSuperview];
        self.messageLabel = nil;
    }
    [self invalidateLayout];
}

- (void)setupButtons
{
    self.buttons = [[NSMutableArray alloc] initWithCapacity:self.items.count];
    for (NSUInteger i = 0; i < self.items.count; i++) {
        UIButton *button = [self buttonForItemIndex:i];
        [self.buttons addObject:button];
        [self.buttonContainerView addSubview:button];
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    SIAlertItem *item = self.items[index];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
	button.tag = index;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [button setAttributedTitle:item.attributedTitle forState:UIControlStateNormal];
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	switch (item.type) {
		case SIAlertViewButtonTypeCancel:
            if (self.cancelButtonBackgroundColor) {
                normalImage = [self imageWithUIColor:self.cancelButtonBackgroundColor];
                highlightedImage = [self imageWithUIColor:self.cancelButtonBackgroundColor];
            }
			break;
		case SIAlertViewButtonTypeDestructive:
			if (self.destructiveButtonBackgroundColor) {
                normalImage = [self imageWithUIColor:self.destructiveButtonBackgroundColor];
                highlightedImage = [self imageWithUIColor:self.destructiveButtonBackgroundColor];
            }
			break;
		case SIAlertViewButtonTypeDefault:
		default:
			if (self.defaultButtonBackgroundColor) {
                normalImage = [self imageWithUIColor:self.defaultButtonBackgroundColor];
                highlightedImage = [self imageWithUIColor:self.defaultButtonBackgroundColor];
            }
			break;
	}
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (UIImage *)imageWithUIColor:(UIColor *)color
{
    CGRect rect = CGRectMake(0, 0, 1, 1);
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
    [color set];
    UIRectFill(rect);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
	[SIAlertView setAnimating:YES]; // set this flag to YES in order to prevent showing another alert in action block
    SIAlertItem *item = self.items[button.tag];
	if (item.action) {
		item.action(self);
	}
	[self dismissAnimated:YES];
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"handler"];
    if (completion) {
        completion();
    }
}

#pragma mark - UIAppearance setters

- (void)setViewBackgroundColor:(UIColor *)viewBackgroundColor
{
    if (_viewBackgroundColor == viewBackgroundColor) {
        return;
    }
    _viewBackgroundColor = viewBackgroundColor;
    self.wrapperView.backgroundColor = viewBackgroundColor;
}

- (void)setSeperatorColor:(UIColor *)seperatorColor
{
    if (_seperatorColor == seperatorColor) {
        return;
    }
    _seperatorColor = seperatorColor;
    self.lineLayer.strokeColor = seperatorColor.CGColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    self.wrapperView.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (_shadowRadius == shadowRadius) {
        return;
    }
    _shadowRadius = shadowRadius;
    self.containerView.layer.shadowRadius = shadowRadius;
    self.containerView.layer.shadowOpacity = shadowRadius > 0 ? 0.5 : 0;
}



- (UIColor *)defaultButtonBackgroundColor
{
    if (!_defaultButtonBackgroundColor) {
        return [[SIAlertView appearance] defaultButtonBackgroundColor];
    }
    return _defaultButtonBackgroundColor;
}

- (UIColor *)cancelButtonBackgroundColor
{
    if (!_cancelButtonBackgroundColor) {
        return [[SIAlertView appearance] cancelButtonBackgroundColor];
    }
    return _cancelButtonBackgroundColor;
}

- (UIColor *)destructiveButtonBackgroundColor
{
    if (!_destructiveButtonBackgroundColor) {
        return [[SIAlertView appearance] destructiveButtonBackgroundColor];
    }
    return _destructiveButtonBackgroundColor;
}

@end
