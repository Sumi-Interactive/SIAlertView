//
//  SIAlertButton.h
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SIAlertView;

typedef NS_ENUM(NSInteger, SIAlertViewButtonType) {
    // use images
    SIAlertViewButtonTypeOKDefault = 0,
    SIAlertViewButtonTypeDestructiveDefault,
    SIAlertViewButtonTypeCancelDefault,
    
    // drawn with core graphics
    SIAlertViewButtonTypeOK,
    SIAlertViewButtonTypeCancel,
    SIAlertViewButtonTypePrimary,
    SIAlertViewButtonTypeInfo,
    SIAlertViewButtonTypeSuccess,
    SIAlertViewButtonTypeWarning,
    SIAlertViewButtonTypeDanger,
    SIAlertViewButtonTypeInverse,
    SIAlertViewButtonTypeTwitter,
    SIAlertViewButtonTypeFacebook,
    SIAlertViewButtonTypePurple
};

typedef void(^SIAlertViewHandler)(SIAlertView *alertView);

@interface SIAlertButton : UIButton

@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) SIAlertViewButtonType type;
@property (nonatomic, copy) SIAlertViewHandler action;

#pragma mark - Initialization
+ (SIAlertButton *)alertButtonWithTitle:(NSString *)aTitle
                                   type:(SIAlertViewButtonType)aType
                                 action:(SIAlertViewHandler)anAction
                                   font:(UIFont *)aFont
                                    tag:(NSInteger)aTag;

+ (SIAlertButton *)alertButtonWithTitle:(NSString *)aTitle
                                  color:(UIColor *)aColor
                                 action:(SIAlertViewHandler)anAction
                                   font:(UIFont *)aFont
                                    tag:(NSInteger)aTag;

@end
