//
//  SIAlertView.h
//  SIAlertView
//


#import <UIKit/UIKit.h>
#import "SIAlertBackgroundWindow.h"
#import "SIAlertButton.h"

extern NSString * const SIAlertViewWillShowNotification;
extern NSString * const SIAlertViewDidShowNotification;
extern NSString * const SIAlertViewWillDismissNotification;
extern NSString * const SIAlertViewDidDismissNotification;


typedef NS_ENUM(NSInteger, SIAlertViewTransitionStyle) {
    SIAlertViewTransitionStyleSlideFromBottom = 0,
    SIAlertViewTransitionStyleSlideFromTop,
    SIAlertViewTransitionStyleFade,
    SIAlertViewTransitionStyleBounce,
    SIAlertViewTransitionStyleDropDown
};

typedef NS_ENUM(NSInteger, SIAlertViewButtonsListStyle) {
    SIAlertViewButtonsListStyleNormal = 0,
    SIAlertViewButtonsListStyleRows
};

typedef NS_ENUM(NSInteger, SIAlertViewStyle) {
    SIAlertViewStyleDefault = 0,
    SIAlertViewStylePlainTextInput,
    SIAlertViewStyleContentView
};

typedef NS_ENUM(NSInteger, SIAlertViewKeyboardStyle) {
    SIAlertViewKeyboardStyleDefault = 0,
    SIAlertViewKeyboardStyleNumberPad,
    SIAlertViewKeyboardStyleNumbersAndPunctuation,
    SIAlertViewKeyboardStyleNamePhonePad
};

@class SIAlertView;

typedef BOOL (^SIAlertViewShouldEnableFirstOtherButtonHandler)(SIAlertView *alertView);


@interface SIAlertView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;
@property (nonatomic, copy) NSString *textFieldText;
@property (nonatomic, copy) NSString *textFieldPlaceholder;
@property (nonatomic, copy, readonly) NSString *inputText;

@property (nonatomic, strong) UIView *contentView;
@property (nonatomic, copy) UIImage *icon;

@property (nonatomic, assign) SIAlertViewStyle alertViewStyle; // default is SIAlertViewStyleDefault
@property (nonatomic, assign) SIAlertViewKeyboardStyle alertViewKeyboardStyle;

@property (nonatomic, assign) SIAlertViewTransitionStyle transitionStyle; // default is SIAlertViewTransitionStyleSlideFromBottom
@property (nonatomic, assign) SIAlertViewBackgroundStyle backgroundStyle; // default is SIAlertViewButtonTypeGradient
@property (nonatomic, assign) SIAlertViewButtonsListStyle buttonsListStyle; // default is SIAlertViewButtonsListStyleNormal

@property (nonatomic, copy) SIAlertViewHandler willShowHandler;
@property (nonatomic, copy) SIAlertViewHandler didShowHandler;
@property (nonatomic, copy) SIAlertViewHandler willDismissHandler;
@property (nonatomic, copy) SIAlertViewHandler didDismissHandler;

@property (nonatomic, copy) SIAlertViewShouldEnableFirstOtherButtonHandler shouldEnableFirstOtherButtonHandler;

@property (nonatomic, readonly, getter = isVisible) BOOL visible;
@property (nonatomic, readonly, getter = isParallaxEffectEnabled) BOOL enabledParallaxEffect;
@property (nonatomic, assign, getter = isTextFieldSecure) BOOL secureTextInput;

@property (nonatomic, strong) UIColor *alertBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *titleColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *messageColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *titleFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *messageFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *buttonFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat cornerRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat shadowRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIFont *textFieldTextFont NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) NSInteger messageMinLineCount NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 3
@property (nonatomic, assign) NSInteger messageMaxLineCount NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 5


- (void)setup;
- (void)invalidateLayout;
- (void)resetTransition;



- (id)initWithTitle:(NSString *)title message:(NSString *)message;

- (void)addCustomButton:(UIButton *)button;

- (void)addAlertButtonWithTitle:(NSString *)title
                           type:(SIAlertViewButtonType)type
                        handler:(SIAlertViewHandler)handler
                        enabled:(BOOL)enabled;

- (void)addAlertButtonWithTitle:(NSString *)title
                          color:(UIColor *)color
                        handler:(SIAlertViewHandler)handler
                        enabled:(BOOL)enabled;

- (void)show;
- (void)dismissAnimated:(BOOL)animated;

- (SIAlertButton *)buttonAtIndex:(NSInteger)buttonIndex;

@end
