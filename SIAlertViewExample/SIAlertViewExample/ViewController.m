//
//  ViewController.m
//  SIAlertViewExample
//
//  Created by Kevin Cao on 13-5-2.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "ViewController.h"
#import "SIAlertView.h"

#define TEST_UIAPPEARANCE 1
#define TEST_AUTO_ROTATE 0

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
#if TEST_UIAPPEARANCE
    UIColor *defaultColor = [UIColor whiteColor];
    [[SIAlertView appearance] setMessageFont:[UIFont systemFontOfSize:14]];
    [[SIAlertView appearance] setTitleColor:[UIColor grayColor]];
    [[SIAlertView appearance] setMessageColor:[UIColor grayColor]];
    [[SIAlertView appearance] setCornerRadius:3];
    [[SIAlertView appearance] setShadowRadius:0];
    [[SIAlertView appearance] setViewBackgroundColor:[UIColor whiteColor]];
    [[SIAlertView appearance] setButtonColor:defaultColor];
    [[SIAlertView appearance] setCancelButtonColor: defaultColor];
    [[SIAlertView appearance] setDestructiveButtonColor:[UIColor whiteColor]];
    
    UIImage *buttonBackground = [self imageWithColor:[UIColor lightGrayColor]];
    
    [[SIAlertView appearance] setDefaultButtonImage:[buttonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(0,0,0,0)] forState:UIControlStateNormal];
    [[SIAlertView appearance] setDefaultButtonImage:[buttonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(0,0,0,0)] forState:UIControlStateNormal];
    [[SIAlertView appearance] setCancelButtonImage:[buttonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(0,0,0,0)] forState:UIControlStateNormal];
    [[SIAlertView appearance] setCancelButtonImage:[buttonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(0,0,0,0)] forState:UIControlStateHighlighted];
    [[SIAlertView appearance] setDestructiveButtonImage:[buttonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(0,0,0,0)] forState:UIControlStateNormal];
    [[SIAlertView appearance] setDestructiveButtonImage:[buttonBackground resizableImageWithCapInsets:UIEdgeInsetsMake(0,0,0,0)] forState:UIControlStateHighlighted];
#endif
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Actions

- (IBAction)alert1:(id)sender
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"" andMessage:@"Count down willShowHandler2 willShowHandler2 willShowHandler2 willShowHandler2"];
    [alertView addButtonWithTitle:@"Button1"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"Button1 Clicked");
                          }];
    [alertView addButtonWithTitle:@"Button2"
                             type:SIAlertViewButtonTypeCancel
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"Button2 Clicked");
                          }];
    [alertView addButtonWithTitle:@"Button3"
                             type:SIAlertViewButtonTypeDestructive
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"Button3 Clicked");
                          }];
    
    alertView.willShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willShowHandler", alertView);
    };
    alertView.didShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didShowHandler", alertView);
    };
    alertView.willDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willDismissHandler", alertView);
    };
    alertView.didDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didDismissHandler", alertView);
    };
    
//    alertView.cornerRadius = 4;
//    alertView.buttonFont = [UIFont boldSystemFontOfSize:12];
    [alertView show];
    
    alertView.title = @"";
//    double delayInSeconds = 1.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        alertView.title = @"2";
//        alertView.titleColor = [UIColor yellowColor];
//        alertView.titleFont = [UIFont boldSystemFontOfSize:30];
//    });
//    delayInSeconds = 2.0;
//    popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        alertView.title = @"1";
//        alertView.titleColor = [UIColor greenColor];
//        alertView.titleFont = [UIFont boldSystemFontOfSize:40];
//    });
//    delayInSeconds = 3.0;
//    popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        NSLog(@"1=====");
//        [alertView dismissAnimated:YES];
//        NSLog(@"2=====");
//    });

}

- (IBAction)alert2:(id)sender
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"" andMessage:@"Message2"];
    [alertView addButtonWithTitle:@"Cancel"
                             type:SIAlertViewButtonTypeCancel
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"Cancel Clicked");
                          }];
    [alertView addButtonWithTitle:@"OK"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"OK Clicked");
                              
                              [self alert3:nil];
                              [self alert3:nil];
                          }];
    alertView.titleColor = [UIColor blueColor];
    alertView.cornerRadius = 10;
    alertView.buttonFont = [UIFont boldSystemFontOfSize:15];
    alertView.transitionStyle = SIAlertViewTransitionStyleBounce;
    
    alertView.willShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willShowHandler2", alertView);
    };
    alertView.didShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didShowHandler2", alertView);
    };
    alertView.willDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willDismissHandler2", alertView);
    };
    alertView.didDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didDismissHandler2", alertView);
    };
    
    [alertView show];
}

id observer1,observer2,observer3,observer4;

- (IBAction)alert3:(id)sender
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 50)];
    view.backgroundColor = [UIColor colorWithRed:0.2 green:0.3 blue:0.4 alpha:0.5];
    
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button-destructive-d.png"]];
    image.frame = CGRectMake(0, 0, 10, 10);
    [view addSubview:image];
    
    
    image = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"button-destructive-d.png"]];
    image.frame = CGRectMake(0, 20, 10, 10);
    [view addSubview:image];
    
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"" andCustomView:view];
    [alertView addButtonWithTitle:@"Cancel"
                             type:SIAlertViewButtonTypeCancel
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"Cancel Clicked");
                          }];
    [alertView addButtonWithTitle:@"OK"
                             type:SIAlertViewButtonTypeDefault
                          handler:^(SIAlertView *alertView) {
                              NSLog(@"OK Clicked");
                          }];
    alertView.transitionStyle = SIAlertViewTransitionStyleDropDown;
    alertView.backgroundStyle = SIAlertViewBackgroundStyleSolid;
    
    alertView.willShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willShowHandler3", alertView);
    };
    alertView.didShowHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didShowHandler3", alertView);
    };
    alertView.willDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, willDismissHandler3", alertView);
    };
    alertView.didDismissHandler = ^(SIAlertView *alertView) {
        NSLog(@"%@, didDismissHandler3", alertView);
    };
    
    observer1 = [[NSNotificationCenter defaultCenter] addObserverForName:SIAlertViewWillShowNotification
                                                                  object:alertView
                                                                   queue:[NSOperationQueue mainQueue]
                                                              usingBlock:^(NSNotification *note) {
                                                                  NSLog(@"%@, -willShowHandler3", alertView);
                                                              }];
    observer2 =[[NSNotificationCenter defaultCenter] addObserverForName:SIAlertViewDidShowNotification
                                                                 object:alertView
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
                                                                 NSLog(@"%@, -didShowHandler3", alertView);
                                                             }];
    observer3 =[[NSNotificationCenter defaultCenter] addObserverForName:SIAlertViewWillDismissNotification
                                                                 object:alertView
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
                                                                 NSLog(@"%@, -willDismissHandler3", alertView);
                                                             }];
    observer4 =[[NSNotificationCenter defaultCenter] addObserverForName:SIAlertViewDidDismissNotification
                                                                 object:alertView
                                                                  queue:[NSOperationQueue mainQueue]
                                                             usingBlock:^(NSNotification *note) {
                                                                 NSLog(@"%@, -didDismissHandler3", alertView);
                                                                 
                                                                 [[NSNotificationCenter defaultCenter] removeObserver:observer1];
                                                                 [[NSNotificationCenter defaultCenter] removeObserver:observer2];
                                                                 [[NSNotificationCenter defaultCenter] removeObserver:observer3];
                                                                 [[NSNotificationCenter defaultCenter] removeObserver:observer4];
                                                                 
                                                                 observer1 = observer2 = observer3 = observer4 = nil;
                                                             }];
    
    [alertView show];
}

- (IBAction)alert4:(id)sender
{
    [self alert1:nil];
    [self alert2:nil];
    [self alert3:nil];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
#if TEST_AUTO_ROTATE
    return YES;
#else
    return NO;
#endif
}

@end
