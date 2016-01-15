//
//  UIWindow+SIUtils.h
//  SIAlertView
//
//  Created by Kevin Cao on 13-11-1.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (SIUtils)

- (UIViewController *)currentViewController;
- (UIViewController *)viewControllerForStatusBarStyle;
- (UIViewController *)viewControllerForStatusBarHidden;

@end
