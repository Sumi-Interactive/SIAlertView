//
//  UIColor+SIAlertView.h
//  SIAlertViewExample
//


#import <UIKit/UIKit.h>

@interface UIColor (SIAlertView)

- (UIColor *)SILightenColorWithValue:(CGFloat)value;
- (UIColor *)SIDarkenColorWithValue:(CGFloat)value;
- (BOOL)SIIsLightColor;

@end
