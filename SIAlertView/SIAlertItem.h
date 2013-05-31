//
//  SIAlertItem.h
//  SIAlertView
//
//
//  Created by Kevin Cao on 5/30/13.
//  Core Graphics integration by Christopher Constable.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SIAlertView;

typedef NS_ENUM(NSInteger, SIAlertViewButtonType) {
    SIAlertViewButtonTypeDefault = 0,
    SIAlertViewButtonTypeDestructive,
    SIAlertViewButtonTypeCancel
};

typedef void(^SIAlertViewHandler)(SIAlertView *alertView);

@interface SIAlertItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) UIColor *buttonColor;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, copy) SIAlertViewHandler action;

- (UIImage *)imageForButton;
- (UIImage *)imageForButtonHighlighted;

@end
