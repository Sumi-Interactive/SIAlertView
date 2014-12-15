//
//  SIAlertView.m
//  SIAlertView
//


#import <QuartzCore/QuartzCore.h>
#import "SIAlertView.h"
#import "SIAlertViewController.h"

NSString * const SIAlertViewWillShowNotification = @"SIAlertViewWillShowNotification";
NSString * const SIAlertViewDidShowNotification = @"SIAlertViewDidShowNotification";
NSString * const SIAlertViewWillDismissNotification = @"SIAlertViewWillDismissNotification";
NSString * const SIAlertViewDidDismissNotification = @"SIAlertViewDidDismissNotification";


#define DEBUG_LAYOUT 0
#define GAP 5
#define CANCEL_BUTTON_PADDING_TOP 5
#define CONTENT_PADDING_LEFT 10
#define CONTENT_PADDING_TOP 12
#define CONTENT_PADDING_BOTTOM 10
#define BUTTON_HEIGHT 44
#define TEXTFIELD_HEIGHT 28
#define CONTAINER_WIDTH 290


static NSMutableArray *__mo_alert_queue;
static BOOL __mo_alert_animating;
static SIAlertBackgroundWindow *__mo_alert_background_window;
static SIAlertView *__mo_alert_current_view;


@interface SIAlertView () <UITextFieldDelegate, MOPaymentViewDelegate>

@property (nonatomic, strong) UIWindow *alertWindow;
@property (nonatomic, strong) UIWindow *oldKeyWindow;
@property (nonatomic, assign, getter = isVisible) BOOL visible;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UITextView *messageTextView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) NSMutableArray *buttons;


@property (nonatomic, assign) CGFloat keyboardOffset;

@property (nonatomic, assign, getter = isLayoutDirty) BOOL layoutDirty;

+ (NSMutableArray *)sharedQueue;
+ (SIAlertView *)currentAlertView;

+ (BOOL)isAnimating;
+ (void)setAnimating:(BOOL)animating;

+ (void)showBackground;
+ (void)hideBackgroundAnimated:(BOOL)animated;

@end



@implementation SIAlertView

#pragma mark - Initialization

+ (void)initialize
{
    if(self != [SIAlertView class])
        return;
    
    SIAlertView *appearance = [self appearance];
    appearance.alertBackgroundColor = [UIColor whiteColor];
    appearance.titleColor = [UIColor blackColor];
    appearance.messageColor = [UIColor darkGrayColor];
    appearance.titleFont = [UIFont boldSystemFontOfSize:20];
    appearance.messageFont = [UIFont systemFontOfSize:16];
    appearance.buttonFont = [UIFont systemFontOfSize:[UIFont buttonFontSize]];
    appearance.cornerRadius = 2;
    appearance.shadowRadius = 8;
    appearance.messageMinLineCount = 3;
    appearance.messageMaxLineCount = 5;
}

- (id)init
{
	return [self initWithTitle:nil message:nil];
}

- (id)initWithTitle:(NSString *)title message:(NSString *)message
{
	self = [super init];
	if (self) {
		_title = title;
        _message = message;
        _enabledParallaxEffect = YES;
		_buttons = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
    [self teardown];
    
    _buttons = nil;
    _title = nil;
    _message = nil;
    
    _willShowHandler = nil;
    _didShowHandler = nil;
    _willDismissHandler = nil;
    _didDismissHandler = nil;
    
    _titleColor = nil;
    _messageColor = nil;
    _titleFont = nil;
    _messageFont = nil;
    _buttonFont = nil;
    _textField = nil;
}

#pragma mark - Class methods

+ (NSMutableArray *)sharedQueue
{
    if (!__mo_alert_queue) {
        __mo_alert_queue = [NSMutableArray array];
    }
    return __mo_alert_queue;
}

+ (SIAlertView *)currentAlertView
{
    return __mo_alert_current_view;
}

+ (void)setCurrentAlertView:(SIAlertView *)alertView
{
    __mo_alert_current_view = alertView;
}

+ (BOOL)isAnimating
{
    return __mo_alert_animating;
}

+ (void)setAnimating:(BOOL)animating
{
    __mo_alert_animating = animating;
}

+ (void)showBackground
{
    if (!__mo_alert_background_window) {
        __mo_alert_background_window = [[SIAlertBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds
                                                                             andStyle:[SIAlertView currentAlertView].backgroundStyle];
        [__mo_alert_background_window makeKeyAndVisible];
        __mo_alert_background_window.alpha = 0;
        [UIView animateWithDuration:0.3
                         animations:^{
                             __mo_alert_background_window.alpha = 1;
                         }];
    }
}

+ (void)hideBackgroundAnimated:(BOOL)animated
{
    if (!animated) {
        [__mo_alert_background_window removeFromSuperview];
        __mo_alert_background_window = nil;
        return;
    }
    [UIView animateWithDuration:0.3
                     animations:^{
                         __mo_alert_background_window.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [__mo_alert_background_window removeFromSuperview];
                         __mo_alert_background_window = nil;
                     }];
}

#pragma mark - Getters

- (NSString *)inputText {
    return self.textField ? self.textField.text : @"";
}


#pragma mark - Setters

- (void)setIcon:(UIImage *)icon
{
    _icon = icon;
    [self invalidateLayout];
}

- (void)setTitle:(NSString *)title
{
    _title = title;
	[self invalidateLayout];
}

- (void)setMessage:(NSString *)message
{
	_message = message;
    self.messageTextView.text = message;

    if (!self.alertViewStyle == SIAlertViewStylePlainTextInput) {
        [self invalidateLayout];
    }
}

#pragma mark - Public

- (void)addCustomButton:(UIButton *)button
{
    [button addTarget:self
               action:@selector(buttonPressed:)
     forControlEvents:UIControlEventTouchUpInside];

    [self.buttons addObject:button];
}

- (void)addAlertButtonWithTitle:(NSString *)title
                           type:(SIAlertViewButtonType)type
                        handler:(SIAlertViewHandler)handler enabled:(BOOL)enabled
{
    SIAlertButton *btn = [SIAlertButton alertButtonWithTitle:title
                                                        type:type
                                                      action:handler
                                                        font:self.buttonFont
                                                         tag:self.buttons.count
                                                     enabled:enabled];
    [self addCustomButton:btn];
}

- (void)addAlertButtonWithTitle:(NSString *)title
                          color:(UIColor *)color
                        handler:(SIAlertViewHandler)handler enabled:(BOOL)enabled
{
    SIAlertButton *btn = [SIAlertButton alertButtonWithTitle:title
                                                        color:color
                                                      action:handler
                                                        font:self.buttonFont
                                                         tag:self.buttons.count
                                                     enabled:enabled];
    [self addCustomButton:btn];
}

- (void)show
{
    
    self.oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
    
    if (![[SIAlertView sharedQueue] containsObject:self]) {
        [[SIAlertView sharedQueue] addObject:self];
    }
    
    if ([SIAlertView isAnimating]) {
        return; // wait for next turn
    }
    
    if (self.isVisible) {
        return;
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
        SIAlertBackgroundWindow *window = [[SIAlertBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel =  UIWindowLevelSIAlert;
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
        
    #ifdef __IPHONE_7_0
            [self addParallaxEffect];
    #endif
        
        [SIAlertView setAnimating:NO];
        
        NSInteger index = [[SIAlertView sharedQueue] indexOfObject:self];
        if (index < [SIAlertView sharedQueue].count - 1) {
            [self dismissAnimated:YES cleanup:NO]; // dismiss to show next alert view
        }
        
        if (self.textField) {
            [self.textField becomeFirstResponder];
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
        
        if(self.textField) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
            [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
            [self.textField resignFirstResponder];
        }
        
        
        [[NSNotificationCenter defaultCenter] postNotificationName:SIAlertViewWillDismissNotification object:self userInfo:nil];
        
    #ifdef __IPHONE_7_0
            [self removeParallaxEffect];
    #endif
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
    
    [self.oldKeyWindow makeKeyWindow];
    self.oldKeyWindow.hidden = NO;
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
    
    CGFloat height = [self preferredHeight];
    CGFloat left = (self.bounds.size.width - CONTAINER_WIDTH) * 0.5;
    CGFloat top = (self.bounds.size.height - height) * 0.5;
    self.containerView.transform = CGAffineTransformIdentity;
    self.containerView.frame = CGRectMake(left, top, CONTAINER_WIDTH, height);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;
    
    CGFloat y = CONTENT_PADDING_TOP;
   
    if (self.iconImageView) {
        y = self.icon.size.height / 2 - self.icon.size.height;
        
        self.iconImageView.image = self.icon;
        CGFloat height = self.icon.size.height;
        self.iconImageView.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
    }

    
	if (self.titleLabel) {
        self.titleLabel.text = self.title;
        CGFloat height = [self heightForTitleLabel];
        self.titleLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
	}
    
    /*
    if (self.messageLabel) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        self.messageLabel.text = self.message;
        CGFloat height = [self heightForMessageLabel];
        self.messageLabel.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
    }*/
    
    if (self.messageTextView) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        self.messageTextView.text = self.message;
        CGFloat height = [self heightForMessageTextView];
        self.messageTextView.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;

        
        
        NSLog(@"%f", height);
        
        self.messageTextView.userInteractionEnabled = [self getNumberOfLinesInUITextView] >= 20; //self.messageMaxLineCount;
        
        NSLog(@"%f", [self getNumberOfLinesInUITextView]);
        
    }
            
    if (self.contentView) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        CGFloat height = self.contentView.bounds.size.height;
        self.contentView.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
    }

    if(self.textField) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        CGFloat height = TEXTFIELD_HEIGHT;
        self.textField.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, height);
        y += height;
        
    }
    
    if (self.buttons.count > 0) {
        if (y > CONTENT_PADDING_TOP) {
            y += GAP;
        }
        
         if (self.buttons.count == 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            CGFloat width = (self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2 - GAP) * 0.5;
            UIButton *button = [self.buttons objectAtIndex:0];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, width, BUTTON_HEIGHT);
            button = [self.buttons objectAtIndex:1];
            button.frame = CGRectMake(CONTENT_PADDING_LEFT + width + GAP, y, width, BUTTON_HEIGHT);
        }
        else {
            for (NSUInteger i = 0; i < self.buttons.count; i++) {
                UIButton *button = self.buttons[i];
                button.frame = CGRectMake(CONTENT_PADDING_LEFT, y, self.containerView.bounds.size.width - CONTENT_PADDING_LEFT * 2, BUTTON_HEIGHT);
                
                if (self.buttons.count > 1) {
                    if (i == self.buttons.count - 1) {
                        id last = [self.buttons lastObject];
                        
                        if([last isKindOfClass:[SIAlertButton class]]
                           && ((SIAlertButton *)last).type == SIAlertViewButtonTypeCancel) {

                            CGRect rect = button.frame;
                            rect.origin.y += CANCEL_BUTTON_PADDING_TOP;
                            button.frame = rect;
                        }
                    }
                    
                    y += BUTTON_HEIGHT + GAP;
                }
            }
        }
    }
}


- (CGFloat)getNumberOfLinesInUITextView {
    
    id<UITextInputTokenizer> tokenizer = self.messageTextView.tokenizer;
    UITextPosition *pos = self.messageTextView.endOfDocument; CGFloat lines = 0;
    
    while (true){
        UITextPosition *lineEnd = [tokenizer positionFromPosition:pos toBoundary:UITextGranularityLine inDirection:UITextStorageDirectionBackward];
        
        if([self.messageTextView comparePosition:pos toPosition:lineEnd] == NSOrderedSame){
            pos = [tokenizer positionFromPosition:lineEnd toBoundary:UITextGranularityCharacter inDirection:UITextStorageDirectionBackward];
            
            if([self.messageTextView comparePosition:pos toPosition:lineEnd] == NSOrderedSame) break;
            
            continue;
        }
        
        lines++; pos = lineEnd;
    }
    
    lines--;
    
    return lines;
    
}
- (CGFloat)preferredHeight
{
	CGFloat height =  CONTENT_PADDING_TOP;
    
    if (self.icon) {
       height += self.icon.size.height / 2 - height;
    }
    
	if (self.title) {
		height += [self heightForTitleLabel];
	}
    
   /*if (self.message) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += [self heightForMessageLabel];
    }*/

    
    if (self.message) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += [self heightForMessageTextView];
    }
    
    
    if (self.contentView) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += self.contentView.frame.size.height;
    }

    
    if (self.textField) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += TEXTFIELD_HEIGHT;
    }
    
    if (self.buttons.count > 0) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        
       if (self.buttons.count <= 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            height += BUTTON_HEIGHT;
        }
        else {
            height += (BUTTON_HEIGHT + GAP) * self.buttons.count - GAP;
            
            if (self.buttons.count > 2) {
                id last = [self.buttons lastObject];
                
                if([last isKindOfClass:[SIAlertButton class]]
                   && ((SIAlertButton *)last).type == SIAlertViewButtonTypeCancel) {
                    height += CANCEL_BUTTON_PADDING_TOP;
                }
            }
        }
    }
    height += CONTENT_PADDING_BOTTOM;
	return height;
}

- (CGFloat)maxHeight {
    
    CGFloat height = CONTENT_PADDING_TOP;
    
    if (self.icon) {
        height += self.icon.size.height / 2 - height;
    }
    
	if (self.title) {
		height += [self heightForTitleLabel];
	}
    
    if (self.contentView) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += self.contentView.frame.size.height;
    }
    
    
    if (self.textField) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        height += TEXTFIELD_HEIGHT;
    }
    
    if (self.buttons.count > 0) {
        if (height > CONTENT_PADDING_TOP) {
            height += GAP;
        }
        
        if (self.buttons.count <= 2 && self.buttonsListStyle == SIAlertViewButtonsListStyleNormal) {
            height += BUTTON_HEIGHT;
        }
        else {
            height += (BUTTON_HEIGHT + GAP) * self.buttons.count - GAP;
            
            if (self.buttons.count > 2) {
                id last = [self.buttons lastObject];
                
                if([last isKindOfClass:[SIAlertButton class]]
                   && ((SIAlertButton *)last).type == SIAlertViewButtonTypeCancel) {
                    height += CANCEL_BUTTON_PADDING_TOP;
                }
            }
        }
    }
    
    height += CONTENT_PADDING_BOTTOM;
	return height;
    
    
}

- (CGFloat)heightForTitleLabel
{
    if (self.titleLabel) {
        
        UIFont *font = self.titleLabel.font;
        
        CGFloat constrainedHeight = font.lineHeight;
        
        NSDictionary *fontAtts = @{NSFontAttributeName : font};
        
        CGRect rect = [self.title boundingRectWithSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, constrainedHeight)
                                               options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesLineFragmentOrigin
                                            attributes:fontAtts
                                               context:nil];
        return rect.size.height;

    }
    return 0;
}

- (CGFloat)heightForMessageLabel
{
   
    CGFloat minHeight = self.messageMinLineCount * self.messageLabel.font.lineHeight;
    if (self.messageLabel) {
        UIFont *font = self.messageLabel.font;
        
        CGFloat maxHeight = self.messageMaxLineCount * font.lineHeight;
        
        NSDictionary *fontAtts = @{NSFontAttributeName : font};
        
        CGRect rect = [self.message boundingRectWithSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, maxHeight)
                                                 options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesLineFragmentOrigin
                                              attributes:fontAtts
                                                 context:nil];
        
        return MAX(minHeight, rect.size.height);
    }
    return minHeight;
}

- (CGFloat)heightForMessageTextView
{
    CGFloat minHeight = self.messageMinLineCount * self.messageTextView.font.lineHeight;
    if (self.messageTextView) {
        UIFont *font = self.messageTextView.font;
        
        //  CGFloat maxHeight = self.messageMaxLineCount * font.lineHeight;
        
        CGFloat height;
        
        if (self.icon) {
            height = [UIScreen mainScreen].bounds.size.height - [self maxHeight] - CONTENT_PADDING_LEFT * 2 - self.icon.size.height / 2;
        }else {
            height = [UIScreen mainScreen].bounds.size.height - [self maxHeight] - CONTENT_PADDING_LEFT * 2;
        }

        NSDictionary *fontAtts = @{NSFontAttributeName : font};
        
        CGRect rect = [self.message boundingRectWithSize:CGSizeMake(CONTAINER_WIDTH - CONTENT_PADDING_LEFT * 2, height)
                                                 options:NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesLineFragmentOrigin
                                              attributes:fontAtts
                                                 context:nil];
        
        
        return MAX(minHeight, rect.size.height);
    }
    return minHeight;
    
}


#pragma mark - Setup

- (void)setup
{
    [self setupContainerView];
    [self updateTitleLabel];
    [self updateIconImageView];
    //[self updateMessageLabel];
    [self updateMessageTextView];

    
    if(self.alertViewStyle == SIAlertViewStylePlainTextInput) {
        [self updateTextField];
    }else if (self.alertViewStyle == SIAlertViewStyleContentView) {
        [self updateContentView];
    }
   
    
    for(UIButton *each in self.buttons) {
        [self.containerView addSubview:each];
    }
    
    if (self.textField) {
        SIAlertButton *button = [self buttonAtIndex:1];
        if (self.shouldEnableFirstOtherButtonHandler) {
            button.enabled = self.shouldEnableFirstOtherButtonHandler(self);
        }
    }

    
    [self invalidateLayout];
}

- (void)teardown
{
    [self.containerView removeFromSuperview];
    self.containerView = nil;
    [self.alertWindow removeFromSuperview];
    self.alertWindow = nil;
    self.textField = nil;
    [self.textField removeFromSuperview];
    self.contentView = nil;
    [self.contentView removeFromSuperview];

    
    self.titleLabel = nil;
    self.iconImageView = nil;
    self.messageLabel = nil;
    self.messageTextView = nil;

    
    [self invalidateLayout];

    
}

- (void)setupContainerView
{
    self.containerView = [[UIView alloc] initWithFrame:self.bounds];
    self.containerView.backgroundColor = self.alertBackgroundColor;
    self.containerView.layer.cornerRadius = self.cornerRadius;
    self.containerView.layer.shadowOffset = CGSizeZero;
    self.containerView.layer.shadowRadius = self.shadowRadius;
    self.containerView.layer.shadowOpacity = 0.5;
    [self addSubview:self.containerView];
}

- (void)updateIconImageView
{
    if (self.icon) {
        if (!self.iconImageView) {
            self.iconImageView = [[UIImageView alloc] initWithFrame:self.bounds];
            [self.iconImageView setContentMode:UIViewContentModeScaleAspectFit];
            [self.containerView addSubview:self.iconImageView];
#if DEBUG_LAYOUT
                        self.titleLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.iconImageView.image = self.icon;
    } else {
        [self.iconImageView removeFromSuperview];
        self.iconImageView = nil;
    }
    [self invalidateLayout];
}


- (void)updateTitleLabel
{
	if (self.title) {
		if (!self.titleLabel) {
			self.titleLabel = [[UILabel alloc] initWithFrame:self.bounds];
			self.titleLabel.textAlignment = NSTextAlignmentCenter;
            self.titleLabel.backgroundColor = [UIColor clearColor];
			self.titleLabel.font = self.titleFont;
            self.titleLabel.textColor = self.titleColor;
            self.titleLabel.adjustsFontSizeToFitWidth = YES;
            self.titleLabel.minimumScaleFactor = 0.75;
			[self.containerView addSubview:self.titleLabel];
#if DEBUG_LAYOUT
            self.titleLabel.backgroundColor = [UIColor redColor];
#endif
		}
		self.titleLabel.text = self.title;
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
            self.messageLabel.textAlignment = NSTextAlignmentCenter;
            self.messageLabel.backgroundColor = [UIColor clearColor];
            self.messageLabel.font = self.messageFont;
            self.messageLabel.textColor = self.messageColor;
            self.messageLabel.numberOfLines = self.messageMaxLineCount;
            [self.containerView addSubview:self.messageLabel];
#if DEBUG_LAYOUT
            self.messageLabel.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageLabel.text = self.message;
    } else {
        [self.messageLabel removeFromSuperview];
        self.messageLabel = nil;
    }
    [self invalidateLayout];
}



- (void)updateMessageTextView
{
    if (self.message) {
        if (!self.messageTextView) {
            self.messageTextView = [[UITextView alloc] initWithFrame:self.bounds];
            self.messageTextView.textAlignment = NSTextAlignmentCenter;
            self.messageTextView.dataDetectorTypes = UIDataDetectorTypeAll; 
            self.messageTextView.backgroundColor = [UIColor clearColor];
            self.messageTextView.font = self.messageFont;
            self.messageTextView.textColor = self.messageColor;
            self.messageTextView.editable = NO;
            self.messageTextView.showsVerticalScrollIndicator = YES;
            self.messageTextView.scrollEnabled = YES;
            self.messageTextView.textContainerInset = UIEdgeInsetsZero;
         
            [self.containerView addSubview:self.messageTextView];
#if DEBUG_LAYOUT
            self.messageTextView.backgroundColor = [UIColor redColor];
#endif
        }
        self.messageTextView.text = self.message;
    } else {
        [self.messageTextView removeFromSuperview];
        self.messageTextView = nil;
    }
    [self invalidateLayout];
}

- (void)updateContentView
{
    if (self.contentView) {
        
        [self.containerView addSubview:self.contentView];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
        
    }else {
        [self.contentView removeFromSuperview];
        self.contentView = nil;
    }
    [self invalidateLayout];
}

- (void)updateTextField
{
    
    if (self.inputText) {
        if(!self.textField) {
            self.textField = [[UITextField alloc] initWithFrame:self.bounds];
            self.textField.delegate = self;
            self.textField.textAlignment = NSTextAlignmentCenter;
            self.textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
            self.textField.placeholder = self.textFieldPlaceholder;
            self.textField.secureTextEntry = self.secureTextInput;
            self.textField.font = self.secureTextInput ? [UIFont systemFontOfSize:15.0f] : self.textFieldTextFont;
            if (self.textFieldText) {
                self.textField.text = self.textFieldText;
            }
            self.textField.layer.borderColor = [UIColor colorWithRed:191/255.0 green:192/255.0 blue:194/255.0 alpha:1.0].CGColor;
            self.textField.layer.cornerRadius = 2.0;
            self.textField.layer.borderWidth = 0.5;
            
            switch (self.alertViewKeyboardStyle) {
                case SIAlertViewKeyboardStyleNumberPad:
                    self.textField.keyboardType = UIKeyboardTypeNumberPad;
                    break;
                    
                case SIAlertViewKeyboardStyleNumbersAndPunctuation:
                    self.textField.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
                    break;
                    
                case SIAlertViewKeyboardStyleNamePhonePad:
                    self.textField.keyboardType = UIKeyboardTypeNamePhonePad;
                    break;
                    
                default:
                    self.textField.keyboardType = UIKeyboardTypeAlphabet;
                    break;
            }
            
            
            [self.containerView addSubview:self.textField];
#if DEBUG_LAYOUT
            self.textField.backgroundColor = [UIColor redColor];
#endif
            
        }
        self.textField.text = self.inputText;
    } else {
        [self.textField removeFromSuperview];
        self.textField = nil;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowNotification:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHideNotification:) name:UIKeyboardWillHideNotification object:nil];
    
    [self invalidateLayout];
}


- (SIAlertButton *)buttonAtIndex:(NSInteger)buttonIndex {
    
    SIAlertButton *button;
    
    if (buttonIndex <= self.buttons.count) {
        button = [self.buttons objectAtIndex:buttonIndex];
    }
 
    return button;
    
}


#pragma mark - Actions

- (void)buttonPressed:(UIButton *)button
{
	[SIAlertView setAnimating:YES]; // set this flag to YES in order to prevent showing another alert in action block

    if([button isKindOfClass:[SIAlertButton class]]) {
        SIAlertButton *btn = (SIAlertButton *)button;
        if(btn.action) {
            btn.action(self);
        }
    }
    
	[self dismissAnimated:YES];
}


#pragma mark UITextFieldDelegate 

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {

    textField.text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if (self.shouldEnableFirstOtherButtonHandler) {
        SIAlertButton *button = [self buttonAtIndex:1];
        if (textField) {
            button.enabled = self.shouldEnableFirstOtherButtonHandler(self);
        }
        
    }


    return NO;
}


- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - Keyboard notification handlers

- (void)keyboardWillShowNotification:(NSNotification *)notification {
    [self moveAlertForKeyboard:notification up:YES];
}
- (void)keyboardWillHideNotification:(NSNotification *)notification {
    [self moveAlertForKeyboard:notification up:NO];
}

- (void)moveAlertForKeyboard:(NSNotification*)notification up:(BOOL)up {
    NSDictionary* userInfo = [notification userInfo];
    NSTimeInterval animationDuration;
    UIViewAnimationCurve animationCurve;
    CGRect keyboardEndFrame;
    
    [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] getValue:&animationCurve];
    [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] getValue:&animationDuration];
    [[userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] getValue:&keyboardEndFrame];
    
    //calculate new position
    CGRect containerFrame = self.containerView.frame;
    CGRect convertedKeyboardFrame = [self convertRect:keyboardEndFrame fromView:self.window];
    CGFloat adjustedHeight = self.bounds.size.height;
    if(up) {
        adjustedHeight -= convertedKeyboardFrame.size.height;
    }
   // CGFloat offSet = up ? CONTENT_PADDING_TOP * 2 : CONTENT_PADDING_TOP / 2;
    containerFrame.origin.y = (adjustedHeight - containerFrame.size.height) / 2; //- offSet;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:animationDuration];
    [UIView setAnimationCurve:animationCurve];

    self.containerView.frame = containerFrame;

    [UIView commitAnimations];
    
    //keyboardOffset is used to adjust the alertView y position on willRotate, i.e. before the rotation occurs. Therefore the height is set dependent of the current orientation
    if(up) {
        self.keyboardOffset = UIInterfaceOrientationIsPortrait([[UIDevice currentDevice] orientation]) ? keyboardEndFrame.size.height : keyboardEndFrame.size.width;
    } else {
        self.keyboardOffset = 0;
    }
}

+ (CGRect) convertRect:(CGRect)rect toView:(UIView *)view {
    UIWindow *window = [view isKindOfClass:[UIWindow class]] ? (UIWindow *) view : [view window];
    return [view convertRect:[window convertRect:rect fromWindow:nil] fromView:nil];
}


# pragma mark Enable parallax effect (iOS7 only)

#ifdef __IPHONE_7_0
- (void)addParallaxEffect
{
    if (_enabledParallaxEffect && NSClassFromString(@"UIInterpolatingMotionEffect"))
    {
        UIInterpolatingMotionEffect *effectHorizontal = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"position.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
        UIInterpolatingMotionEffect *effectVertical = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"position.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
        
        [effectHorizontal setMaximumRelativeValue:@(20.0f)];
        [effectHorizontal setMinimumRelativeValue:@(-20.0f)];
        [effectVertical setMaximumRelativeValue:@(25.0f)];
        [effectVertical setMinimumRelativeValue:@(-25.0f)];
        
        [self.containerView addMotionEffect:effectHorizontal];
        [self.containerView addMotionEffect:effectVertical];
    }
}

- (void)removeParallaxEffect
{
    if (_enabledParallaxEffect && NSClassFromString(@"UIInterpolatingMotionEffect"))
    {
        [self.containerView.motionEffects enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [self.containerView removeMotionEffect:obj];
        }];
    }
}
#endif


#pragma mark - Animation delegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    void(^completion)(void) = [anim valueForKey:@"handler"];
    if (completion) {
        completion();
    }
}

#pragma mark - UIAppearance setters

- (void)setAlertBackgroundColor:(UIColor *)alertBackgroundColor
{
    if(_alertBackgroundColor == alertBackgroundColor) {
        return;
    }
    _alertBackgroundColor = alertBackgroundColor;
    self.containerView.backgroundColor = alertBackgroundColor;
    [self invalidateLayout];
}

- (void)setTitleFont:(UIFont *)titleFont
{
    if (_titleFont == titleFont) {
        return;
    }
    _titleFont = titleFont;
    self.titleLabel.font = titleFont;
    [self invalidateLayout];
}

- (void)setMessageFont:(UIFont *)messageFont
{
    if (_messageFont == messageFont) {
        return;
    }
    _messageFont = messageFont;
    self.messageLabel.font = messageFont;
    [self invalidateLayout];
}

- (void)setTitleColor:(UIColor *)titleColor
{
    if (_titleColor == titleColor) {
        return;
    }
    _titleColor = titleColor;
    self.titleLabel.textColor = titleColor;
}

- (void)setMessageColor:(UIColor *)messageColor
{
    if (_messageColor == messageColor) {
        return;
    }
    _messageColor = messageColor;
    self.messageLabel.textColor = messageColor;
}

- (void)setButtonFont:(UIFont *)buttonFont
{
    if (_buttonFont == buttonFont) {
        return;
    }
    _buttonFont = buttonFont;
    for (UIButton *button in self.buttons) {
        button.titleLabel.font = buttonFont;
    }
}

- (void)setCornerRadius:(CGFloat)cornerRadius
{
    if (_cornerRadius == cornerRadius) {
        return;
    }
    _cornerRadius = cornerRadius;
    self.containerView.layer.cornerRadius = cornerRadius;
}

- (void)setShadowRadius:(CGFloat)shadowRadius
{
    if (_shadowRadius == shadowRadius) {
        return;
    }
    _shadowRadius = shadowRadius;
    self.containerView.layer.shadowRadius = shadowRadius;
}

- (void)setMessageMaxLineCount:(NSInteger)messageMaxLineCount {
    _messageMaxLineCount = messageMaxLineCount;
}

- (void)setMessageMinLineCount:(NSInteger)messageMinLineCount {
    _messageMinLineCount = messageMinLineCount;
}

- (void)setTextFieldTextFont:(UIFont *)textFieldTextFont {
    
    if (_textFieldTextFont == textFieldTextFont) {
        return;
    }
    _textFieldTextFont = textFieldTextFont;
    self.textField.font = textFieldTextFont;
}

- (void)setTextFieldText:(NSString *)textFieldText  {
    
    
    if (_textFieldText == textFieldText) {
        return;
    }
    _textFieldText = textFieldText;
    self.textField.text = textFieldText;
}

@end
