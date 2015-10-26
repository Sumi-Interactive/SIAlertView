//
//  SIAlertButton.h
//  SIAlertView
//


#import <Foundation/Foundation.h>

@class SIAlertView;

typedef NS_ENUM(NSInteger, SIAlertViewButtonType) {
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
                                    tag:(NSInteger)aTag
                                    enabled:(BOOL)enabled;

+ (SIAlertButton *)alertButtonWithTitle:(NSString *)aTitle
                                  color:(UIColor *)aColor
                                 action:(SIAlertViewHandler)anAction
                                   font:(UIFont *)aFont
                                    tag:(NSInteger)aTag
                                     enabled:(BOOL)enabled;

@end
