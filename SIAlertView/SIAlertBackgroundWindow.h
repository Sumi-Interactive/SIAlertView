//
//  SIAlertBackgroundWindow.h
//  SIAlertView
//


#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SIAlertViewBackgroundStyle) {
    SIAlertViewBackgroundStyleGradient,
    SIAlertViewBackgroundStyleSolid,
    SIAlertViewBackgroundStyleClear
};

const UIWindowLevel UIWindowLevelSIAlert;
const UIWindowLevel UIWindowLevelSIAlertBackground;

@interface SIAlertBackgroundWindow : UIWindow

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame andStyle:(SIAlertViewBackgroundStyle)style;

@end
