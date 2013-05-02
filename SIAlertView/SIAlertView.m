//
//  SIAlertView.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertView.h"
#import <QuartzCore/QuartzCore.h>

#define DEBUG_LAYOUT 0

#define MESSAGE_MIN_LINE_COUNT 3
#define MESSAGE_MAX_LINE_COUNT 5
#define GAP 10
#define CANCEL_BUTTON_PADDING_TOP 5
#define CONTENT_PADDING_LEFT 10
#define CONTENT_PADDING_TOP 12
#define CONTENT_PADDING_BOTTOM 10
#define BUTTON_HEIGHT 44

@class SIBackgroundWindow;
@class SIAlertViewController;

@protocol SIAlertViewControllerDelegate <NSObject>

- (void)viewController:(SIAlertViewController *)viewController clickedButtonIndex:(NSInteger)buttonIndex;

@end

static NSMutableArray *__si_alert_queue;
static BOOL __si_alert_animating;
static SIBackgroundWindow *__si_alert_background_window;

@interface SIAlertView () <SIAlertViewControllerDelegate>

@property (nonatomic, strong) NSMutableArray *items;

@property (nonatomic, strong) SIAlertViewController *viewController;
@property (nonatomic, strong) UIWindow *alertWindow;

@property (nonatomic, assign, getter = isVisible) BOOL visible;

+ (SIBackgroundWindow *)sharedBackground;
+ (NSMutableArray *)sharedQueue;
+ (BOOL)isAnimating;
+ (void)setAnimating:(BOOL)animating;
+ (void)removeSharedBackground;

@end

#pragma mark - SIBackgroundWindow

@interface SIBackgroundWindow : UIWindow

- (void)show;
- (void)hideAnimated:(BOOL)animated;

@end

@interface SIBackgroundWindow ()

@property (nonatomic, strong) UIView *backgroundView;

@end

@implementation SIBackgroundWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        self.backgroundView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        self.backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:self.backgroundView];
        
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelAlert;
    }
    return self;
}

- (void)show
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundView.alpha = 1;
                     }];
}

- (void)hideAnimated:(BOOL)animated
{
    if (!animated) {
        [SIAlertView removeSharedBackground];
        return;
    }
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.backgroundView.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [SIAlertView removeSharedBackground];
                     }];
}

@end

#pragma mark - SIAlertItem

@interface SIAlertItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, copy) SIAlertViewHandler action;

@end

@implementation SIAlertItem

@end

#pragma mark - SIAlertViewController

@interface SIAlertViewController : UIViewController

@property (nonatomic, strong) SIAlertView *alertView;
@property (nonatomic, weak) id<SIAlertViewControllerDelegate> delegate;

@property (nonatomic, copy) void(^transitionCompletion)(void);

- (CGFloat)preferredHeight;
- (void)invaliadateLayout;
- (void)transitionInCompletion:(void(^)(void))completion;
- (void)transitionOutCompletion:(void(^)(void))completion;

@end

@interface SIAlertViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, readonly) UIView *containerView;
@property (nonatomic, strong) NSMutableArray *buttons;

@property (nonatomic, assign, getter = isLayoutDirty) BOOL layoutDirty;

@end

@implementation SIAlertViewController

#pragma mark - View life cycle

- (void)loadView
{
    self.view = self.alertView;
    
    [self setupContainerView];
	[self updateTitleLabel];
    [self updateMessageLabel];
    [self setupButtons];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self invaliadateLayout];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [self resetTransition];
    [self invaliadateLayout];
}

- (void)viewWillLayoutSubviews
{
    [self validateLayout];
}

#pragma mark - Public

- (void)transitionInCompletion:(void(^)(void))completion
{
    switch (self.alertView.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            CGRect originalRect = rect;
            rect.origin.y = self.view.bounds.size.height;
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
            // store completion block
            self.transitionCompletion = completion;
            
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(0.01), @(1.2), @(0.9), @(1)];
            animation.keyTimes = @[@(0), @(0.4), @(0.6), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.5;
            animation.delegate = self;
            [self.containerView.layer addAnimation:animation forKey:@"bouce"];
        }
            break;
        case SIAlertViewTransitionStyleDropDown:
        {
            // store completion block
            self.transitionCompletion = completion;
            
            CGFloat y = self.containerView.center.y;
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"position.y"];
            animation.values = @[@(y - self.view.bounds.size.height), @(y + 20), @(y - 10), @(y)];
            animation.keyTimes = @[@(0), @(0.5), @(0.75), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.4;
            animation.delegate = self;
            [self.containerView.layer addAnimation:animation forKey:@"dropdown"];
        }
            break;
        default:
            break;
    }
}

- (void)transitionOutCompletion:(void(^)(void))completion
{
    switch (self.alertView.transitionStyle) {
        case SIAlertViewTransitionStyleSlideFromBottom:
        {
            CGRect rect = self.containerView.frame;
            rect.origin.y = self.view.bounds.size.height;
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
            // store completion block
            self.transitionCompletion = completion;
            
            CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
            animation.values = @[@(1), @(1.2), @(0.01)];
            animation.keyTimes = @[@(0), @(0.4), @(1)];
            animation.timingFunctions = @[[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut], [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            animation.duration = 0.35;
            animation.delegate = self;
            [self.containerView.layer addAnimation:animation forKey:@"bounce"];
            
            self.containerView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
            break;
        case SIAlertViewTransitionStyleDropDown:
        {
            CGPoint point = self.containerView.center;
            point.y += self.view.bounds.size.height;
            [UIView animateWithDuration:0.3
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                                 self.containerView.center = point;
                                 self.containerView.transform = CGAffineTransformMakeRotation(0.3);
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

#pragma mark - Layout

- (void)invaliadateLayout
{
    self.layoutDirty = YES;
    [self.view setNeedsLayout];
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
    
    CGFloat height = [self preferredHeight];
    CGFloat left = (self.view.bounds.size.width - 300) * 0.5;
    CGFloat top = (self.view.bounds.size.height - height) * 0.5;
    self.containerView.frame = CGRectMake(left, top, 300, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;
    
    CGFloat y = CONTENT_PADDING_TOP;
	if (self.titleLabel) {
        self.titleLabel.text = self.alertView.title;
        CGFloat height = [self heightForTitleLabel];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
	}
    if (self.messageLabel) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        self.messageLabel.text = self.alertView.message;
        CGFloat height = [self heightForMessageLabel];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
    }
    if (self.alertView.items.count > 0) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        if (self.alertView.items.count == 2) {
            CGFloat width = (self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2 - GAP) * 0.5;
            UIButton *button = self.buttons[0];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, width, BUTTON_HEIGHT);
            button = self.buttons[1];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT + width + GAP, y, width, BUTTON_HEIGHT);
        } else {
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, BUTTON_HEIGHT);
                if (self.buttons.count > 1) {
                    if (i == self.buttons.count - 1 && ((SIAlertItem *)self.alertView.items[i]).type == SIAlertViewButtonTypeCancel) {
                        CGRect rect = button.frame;
                        rect.origin.y += CANCEL_BUTTON_PADDING_TOP;
                        button.frame = rect;
                    }
                    y += BUTTON_HEIGHT + GAP;
                }
            }
        }
    }
}

- (CGFloat)preferredHeight
{
	CGFloat height = CONTENT_PADDING_TOP;
	if (self.alertView.title) {
		height += [self heightForTitleLabel];
	}
    if (self.alertView.message) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += [self heightForMessageLabel];
    }
    if (self.alertView.items.count > 0) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        if (self.alertView.items.count <= 2) {
            height += BUTTON_HEIGHT;
        } else {
            height += (BUTTON_HEIGHT + GAP) * self.alertView.items.count - GAP;
            if (self.buttons.count > 2 && ((SIAlertItem *)[self.alertView.items lastObject]).type == SIAlertViewButtonTypeCancel) {
                height += CANCEL_BUTTON_PADDING_TOP;
            }
        }
    }
    height += CONTENT_PADDING_BOTTOM;
	return height;
}

- (CGFloat)heightForTitleLabel
{
    if (self.titleLabel) {
        CGSize size = [self.alertView.title sizeWithFont:self.titleLabel.font
                                         minFontSize:self.titleLabel.font.pointSize * self.titleLabel.minimumScaleFactor
                                      actualFontSize:nil
                                            forWidth:self.titleLabel.bounds.size.width
                                       lineBreakMode:self.titleLabel.lineBreakMode];
        return size.height;
    }
    return 0;
}

- (CGFloat)heightForMessageLabel
{
    CGFloat minHeight = MESSAGE_MIN_LINE_COUNT * self.messageLabel.font.lineHeight;
    if (self.messageLabel) {
        CGFloat maxHeight = MESSAGE_MAX_LINE_COUNT * self.messageLabel.font.lineHeight;
        CGSize size = [self.alertView.message sizeWithFont:self.messageLabel.font
                                     constrainedToSize:CGSizeMake(self.messageLabel.bounds.size.width, maxHeight)
                                         lineBreakMode:self.messageLabel.lineBreakMode];
        
        return MAX(minHeight, MIN(maxHeight, size.height));
    }
    return minHeight;
}

#pragma mark - Private

- (void)setupContainerView
{
    _containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    _containerView.backgroundColor = [UIColor whiteColor];
    _containerView.layer.cornerRadius = self.alertView.cornerRadius;
    _containerView.layer.shadowOffset = CGSizeZero;
    _containerView.layer.shadowRadius = 8;
    _containerView.layer.shadowOpacity = 0.5;
    [self.view addSubview:_containerView];
}

- (void)updateTitleLabel
{
	if (self.alertView.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.font = self.alertView.titleFont;
            self.titleLabel.textColor = self.alertView.titleColor;
            self.titleLabel.adjustsFontSizeToFitWidth = YES;
            self.titleLabel.minimumScaleFactor = 0.75;
			[self.containerView addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
		}
		self.titleLabel.text = self.alertView.title;
	} else {
		[self.titleLabel removeFromSuperview];
		self.titleLabel = nil;
	}
    [self invaliadateLayout];
}

- (void)updateMessageLabel
{
    if (self.alertView.message) {
        if (!self.messageLabel) {
            self.messageLabel = [[UILabel alloc] initWithFrame:self.view.bounds];
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = self.alertView.messageFont;
            self.messageLabel.textColor = self.alertView.messageColor;
            self.messageLabel.numberOfLines = MESSAGE_MAX_LINE_COUNT;
            [self.containerView addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageLabel.text = self.alertView.message;
    } else {
        [self.messageLabel removeFromSuperview];
        self.messageLabel = nil;
    }
    [self invaliadateLayout];
}

- (void)setupButtons
{
    self.buttons = [[NSMutableArray alloc] initWithCapacity:self.alertView.items.count];
    for (NSUInteger i = 0; i < self.alertView.items.count; i++) {
        UIButton *button = [self buttonForItemIndex:i];
        [self.buttons addObject:button];
        [self.containerView addSubview:button];
    }
}

- (UIButton *)buttonForItemIndex:(NSUInteger)index
{
    SIAlertItem *item = self.alertView.items[index];
	UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.tag = index;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = self.alertView.buttonFont;
	[button setTitle:item.title forState:UIControlStateNormal];
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	switch (item.type) {
		case SIAlertViewButtonTypeCancel:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-cancel"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-cancel-d"];
			[button setTitleColor:[UIColor colorWithWhite:0.3 alpha:1] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.3 alpha:0.8] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDestructive:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive-d"];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:1 alpha:0.8] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDefault:
		default:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default-d"];
			[button setTitleColor:[UIColor colorWithWhite:0.4 alpha:1] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.4 alpha:0.8] forState:UIControlStateHighlighted];
			break;
	}
	CGFloat hInset = floorf(normalImage.size.width / 2);
	CGFloat vInset = floorf(normalImage.size.height / 2);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	normalImage = [normalImage resizableImageWithCapInsets:insets];
	highlightedImage = [highlightedImage resizableImageWithCapInsets:insets];
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
	[button addTarget:self action:@selector(buttonAction:) forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}

- (void)resetTransition
{
    [self.containerView.layer removeAllAnimations];
}

#pragma mark - Actions

- (void)buttonAction:(UIButton *)button
{
	[self.delegate viewController:self clickedButtonIndex:button.tag];
}

#pragma mark - CAAnimation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (self.transitionCompletion) {
        self.transitionCompletion();
        self.transitionCompletion = nil;
    }
}

@end

#pragma mark - SIAlert

@implementation SIAlertView

- (id)init
{
	return [self initWithTitle:nil andMessage:nil];
}

- (id)initWithTitle:(NSString *)title andMessage:(NSString *)message
{
	self = [super init];
	if (self) {
		_title = title;
        _message = message;
		self.items = [[NSMutableArray alloc] init];
	}
	return self;
}

#pragma mark -

+ (SIBackgroundWindow *)sharedBackground
{
    if (!__si_alert_background_window) {
        __si_alert_background_window = [[SIBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        [__si_alert_background_window makeKeyAndVisible];
    }
    return __si_alert_background_window;
}

+ (NSMutableArray *)sharedQueue
{
    if (!__si_alert_queue) {
        __si_alert_queue = [NSMutableArray array];
    }
    return __si_alert_queue;
}

+ (BOOL)isAnimating
{
    return __si_alert_animating;
}

+ (void)setAnimating:(BOOL)animating
{
    __si_alert_animating = animating;
}

+ (void)removeSharedBackground
{
    [__si_alert_background_window removeFromSuperview];
    __si_alert_background_window = nil;
}

#pragma mark - Setters

- (void)setTitle:(NSString *)title
{
    _title = title;
	[self.viewController invaliadateLayout];
}

- (void)setMessage:(NSString *)message
{
	_message = message;
    [self.viewController invaliadateLayout];
}

#pragma mark - Public

- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler
{
    SIAlertItem *item = [[SIAlertItem alloc] init];
	item.title = title;
	item.type = type;
	item.action = handler;
	[self.items addObject:item];
}

- (void)show
{
    if (![[SIAlertView sharedQueue] containsObject:self]) {
        [[SIAlertView sharedQueue] addObject:self];
    }
    
    if ([SIAlertView isAnimating]) {
        return; // wait for next turn
    }
    
    if (self.willShowHandler) {
        self.willShowHandler(self);
    }
    
    // transition for background if needed
    if ([SIAlertView sharedQueue].count == 1) {
        [[SIAlertView sharedBackground] show];
    }
    
    self.viewController = [[SIAlertViewController alloc] initWithNibName:nil bundle:nil];
    self.viewController.alertView = self;
    self.viewController.delegate = self;
    
    if (!self.alertWindow) {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel = UIWindowLevelAlert;
        window.rootViewController = self.viewController;
        self.alertWindow = window;
    }
    [self.alertWindow makeKeyAndVisible];
    
    self.visible = YES;
    
    [SIAlertView setAnimating:YES];
    
    [self.viewController transitionInCompletion:^{
        if (self.didShowHandler) {
            self.didShowHandler(self);
        }
        
        [SIAlertView setAnimating:NO];
        
        [self showNextIfNeededForAlert:self];
    }];
    
    // hide previous alert
    NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
    if (index > 0) {
        SIAlertView *alert = [SIAlertView sharedQueue][index - 1];
        alert.alertWindow.hidden = YES;
        alert.visible = NO;
    }
}

- (void)dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(BOOL)animated
{
    if (self.willDismissHandler) {
        self.willDismissHandler(self);
    }
    
    void (^dismissComplete)(void) = ^{
        self.visible = NO;
        
        [self.alertWindow removeFromSuperview];
        self.alertWindow = nil;
        self.viewController = nil;
        
        [[SIAlertView sharedQueue] removeObject:self];
        
        [SIAlertView setAnimating:NO];
        
        if (self.didDismissHandler) {
            self.didDismissHandler(self);
        }
        
        if ([SIAlertView sharedQueue].count > 0) {
            
            SIAlertView *alert = [[SIAlertView sharedQueue] lastObject];
            
            if (alert.viewController) {
                // show previous alert
                alert.alertWindow.hidden = NO;
                alert.visible = YES;
                
                // transition in again
                [alert.viewController transitionInCompletion:^{
                    [SIAlertView setAnimating:NO];
                    
                    [self showNextIfNeededForAlert:alert];
                }];
            } else {
                // show new added alert
                [alert show];
            }
        }
    };
    
    if (animated) {
        [SIAlertView setAnimating:YES];
        [self.viewController transitionOutCompletion:dismissComplete];
        
        if ([SIAlertView sharedQueue].count == 1) {
            [[SIAlertView sharedBackground] hideAnimated:YES];
        }
        
    } else {
        dismissComplete();
        
        if ([SIAlertView sharedQueue].count == 1) {
            [[SIAlertView sharedBackground] hideAnimated:NO];
        }
    }
}

#pragma mark - Private

- (void)showNextIfNeededForAlert:(SIAlertView *)alert
{
    NSInteger index = [[SIAlertView sharedQueue] indexOfObject:alert];
    if (index < [SIAlertView sharedQueue].count - 1) {
        SIAlertView *alert = [SIAlertView sharedQueue][index + 1];
        [alert show];
    }
}

#pragma mark - SIAlertViewControllerDelegate

- (void)viewController:(SIAlertViewController *)viewController clickedButtonIndex:(NSInteger)buttonIndex
{
    [SIAlertView setAnimating:YES];
    SIAlertItem *item = self.items[buttonIndex];
	if (item.action) {
		item.action(self);
	}
	[self dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

#pragma mark - UIAppearance getters

- (UIFont *)titleFont
{
    if (!_titleFont) {
        _titleFont = [[[self class] appearance] titleFont];
    }
    return _titleFont ? _titleFont : [UIFont boldSystemFontOfSize:20];
}

- (UIFont *)messageFont
{
    if (!_messageFont) {
        _messageFont = [[[self class] appearance] messageFont];
    }
    return _messageFont ? _messageFont : [UIFont systemFontOfSize:16];
}

- (UIFont *)buttonFont
{
    if (!_buttonFont) {
        _buttonFont = [[[self class] appearance] buttonFont];
    }
    return _buttonFont ? _buttonFont : [UIFont systemFontOfSize:[UIFont buttonFontSize]];
}

- (UIColor *)titleColor
{
    if(!_titleColor) {
        _titleColor = [[[self class] appearance] titleColor];
    }
    
    return _titleColor ? _titleColor : [UIColor blackColor];
}

- (UIColor *)messageColor
{
    if(!_messageColor) {
        _messageColor = [[[self class] appearance] messageColor];
    }
    
    return _messageColor ? _messageColor : [UIColor darkGrayColor];
}

- (CGFloat)cornerRadius
{
    if (_cornerRadius == 0) {
        _cornerRadius = [[[self class] appearance] cornerRadius];
    }
    
    return _cornerRadius;
}

@end
