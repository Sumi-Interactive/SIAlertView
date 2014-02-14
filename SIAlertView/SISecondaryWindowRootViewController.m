//
//  SIFloatWindowRootViewController.m
//
//  Created by Kevin Cao on 13-11-9.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SISecondaryWindowRootViewController.h"
#import "UIWindow+SIUtils.h"

#define MAIN_WINDOW [UIApplication sharedApplication].windows[0]

@interface SISecondaryWindowRootViewController ()

@end

@implementation SISecondaryWindowRootViewController

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    
#ifdef __IPHONE_7_0
    // give the current view controller in charge a chance to update status bar
    if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
        [self setNeedsStatusBarAppearanceUpdate];
    }
#endif
}

#pragma mark - Rotation

- (NSUInteger)supportedInterfaceOrientations
{
    UIViewController *viewController = [MAIN_WINDOW currentViewController];
    if (viewController) {
        return [viewController supportedInterfaceOrientations];
    }
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    UIViewController *viewController = [MAIN_WINDOW currentViewController];
    if (viewController) {
        return [viewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
    }
    return YES;
}

- (BOOL)shouldAutorotate
{
    UIViewController *viewController = [MAIN_WINDOW currentViewController];
    if (viewController) {
        return [viewController shouldAutorotate];
    }
    return YES;
}

#ifdef __IPHONE_7_0

#pragma mark - Status Bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return [[MAIN_WINDOW viewControllerForStatusBarStyle] preferredStatusBarStyle];
}

- (BOOL)prefersStatusBarHidden
{
    return [[MAIN_WINDOW viewControllerForStatusBarHidden] prefersStatusBarHidden];
}
#endif

@end
