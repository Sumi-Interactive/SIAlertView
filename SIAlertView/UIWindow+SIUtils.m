//
//  UIWindow+SIUtils.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-11-1.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "UIWindow+SIUtils.h"

@implementation UIWindow (SIUtils)

- (UIViewController *)currentViewController
{
    UIViewController *viewController = self.rootViewController;
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }
    return viewController;
}

#ifdef __IPHONE_7_0

- (UIViewController *)viewControllerForStatusBarStyle
{
    UIViewController *currentViewController = [self currentViewController];
    
    while ([currentViewController childViewControllerForStatusBarStyle]) {
        currentViewController = [currentViewController childViewControllerForStatusBarStyle];
    }
    return currentViewController;
}

- (UIViewController *)viewControllerForStatusBarHidden
{
    UIViewController *currentViewController = [self currentViewController];
    
    while ([currentViewController childViewControllerForStatusBarHidden]) {
        currentViewController = [currentViewController childViewControllerForStatusBarHidden];
    }
    return currentViewController;
}

#endif

@end
