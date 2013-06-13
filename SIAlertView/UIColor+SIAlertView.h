//
//  UIColor+SIAlertView.h
//  SIAlertViewExample
//
//  Created by Jesse Squires on 6/11/13.
//  Copyright (c) 2013 Jesse Squires. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (SIAlertView)

- (UIColor *)lightenColorWithValue:(CGFloat)value;
- (UIColor *)darkenColorWithValue:(CGFloat)value;
- (BOOL)isLightColor;

@end
