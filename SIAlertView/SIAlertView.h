//
//  SIAlertView.h
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const SIAlertViewWillShowNotification;
extern NSString *const SIAlertViewDidShowNotification;
extern NSString *const SIAlertViewWillDismissNotification;
extern NSString *const SIAlertViewDidDismissNotification;

typedef NS_ENUM(NSInteger, SIAlertViewButtonType) {
    SIAlertViewButtonTypeDefault = 0,
    SIAlertViewButtonTypeDestructive,
    SIAlertViewButtonTypeCancel
};

typedef NS_ENUM(NSInteger, SIAlertViewBackgroundStyle) {
    SIAlertViewBackgroundStyleGradient = 1,
    SIAlertViewBackgroundStyleSolid = 0,
};

typedef NS_ENUM(NSInteger, SIAlertViewButtonsListStyle) {
    SIAlertViewButtonsListStyleNormal = 0,
    SIAlertViewButtonsListStyleRows
};

typedef NS_ENUM(NSInteger, SIAlertViewTransitionStyle) {
    SIAlertViewTransitionStyleSlideFromBottom = 0,
    SIAlertViewTransitionStyleSlideFromTop,
    SIAlertViewTransitionStyleFade,
    SIAlertViewTransitionStyleBounce,
    SIAlertViewTransitionStyleDropDown
};

@class SIAlertView;
typedef void(^SIAlertViewHandler)(SIAlertView *alertView);

@interface SIAlertView : UIView

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, copy) NSAttributedString *attributedTitle;
@property (nonatomic, copy) NSAttributedString *attributedMessage;

@property (nonatomic, assign) SIAlertViewTransitionStyle transitionStyle; // default is SIAlertViewTransitionStyleSlideFromBottom
@property (nonatomic, assign) SIAlertViewBackgroundStyle backgroundStyle; // default is SIAlertViewButtonTypeSolid
@property (nonatomic, assign) SIAlertViewButtonsListStyle buttonsListStyle; // default is SIAlertViewButtonsListStyleNormal

@property (nonatomic, copy) SIAlertViewHandler willShowHandler;
@property (nonatomic, copy) SIAlertViewHandler didShowHandler;
@property (nonatomic, copy) SIAlertViewHandler willDismissHandler;
@property (nonatomic, copy) SIAlertViewHandler didDismissHandler;

@property (nonatomic, readonly, getter = isVisible) BOOL visible;

// theme

@property (nonatomic, strong) UIColor *viewBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is [UIColor white]
@property (nonatomic, strong) UIColor *seperatorColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is [UIColor colorWithWhite:0 alpha:0.1]
@property (nonatomic, assign) CGFloat cornerRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 2.0
@property (nonatomic, assign) CGFloat shadowRadius NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR; // default is 0.0

@property (nonatomic, strong) NSDictionary *titleAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDictionary *messageAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;

@property (nonatomic, strong) NSDictionary *defaultButtonAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDictionary *cancelButtonAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) NSDictionary *destructiveButtonAttributes NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *defaultButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *cancelButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *destructiveButtonBackgroundColor NS_AVAILABLE_IOS(5_0) UI_APPEARANCE_SELECTOR;


- (id)initWithTitle:(NSString *)title message:(NSString *)message;
- (id)initWithTitle:(NSString *)title message:(NSString *)message cancelButton:(NSString *)canelButton handler:(SIAlertViewHandler)handler;
- (id)initWithAttributedTitle:(NSAttributedString *)attributedTitle attributedMessage:(NSAttributedString *)attributedMessage;
- (void)addButtonWithTitle:(NSString *)title type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler;
- (void)addButtonWithTitle:(NSString *)title font:(UIFont *)font color:(UIColor *)color type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler;
- (void)addButtonWithAttributedTitle:(NSAttributedString *)attributedTitle type:(SIAlertViewButtonType)type handler:(SIAlertViewHandler)handler;

- (void)show;
- (void)dismissAnimated:(BOOL)animated;

@end
