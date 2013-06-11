//
//  ViewController.m
//  SIAlertViewExample
//
//  Created by Kevin Cao on 13-5-2.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "ViewController.h"
#import "SIAlertView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [[SIAlertView appearance] setMessageFont:[UIFont systemFontOfSize:13]];
    [[SIAlertView appearance] setTitleColor:[UIColor greenColor]];
    [[SIAlertView appearance] setMessageColor:[UIColor purpleColor]];
    [[SIAlertView appearance] setCornerRadius:12];
    [[SIAlertView appearance] setShadowRadius:20];
}

#pragma mark - Actions

- (IBAction)alert1:(id)sender
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Title1" message:@"Count down"];
    
    [alertView addAlertButtonWithTitle:@"Button1"
                                  type:SIAlertViewButtonTypeOKDefault
                               handler:^(SIAlertView *alertView) {
                                   NSLog(@"Button1 Clicked");
                               }];
    [alertView addAlertButtonWithTitle:@"Button2"
                                  type:SIAlertViewButtonTypeOKDefault
                               handler:^(SIAlertView *alertView) {
                                   NSLog(@"Button2 Clicked");
                               }];
    [alertView addAlertButtonWithTitle:@"Button3"
                                  type:SIAlertViewButtonTypeDestructiveDefault
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
    
    alertView.title = @"3";
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        alertView.title = @"2";
        alertView.titleColor = [UIColor yellowColor];
        alertView.titleFont = [UIFont boldSystemFontOfSize:30];
    });
    delayInSeconds = 2.0;
    popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        alertView.title = @"1";
        alertView.titleColor = [UIColor greenColor];
        alertView.titleFont = [UIFont boldSystemFontOfSize:40];
    });
    delayInSeconds = 3.0;
    popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        NSLog(@"1=====");
        [alertView dismissAnimated:YES];
        NSLog(@"2=====");
    });
    
}

- (IBAction)alert2:(id)sender
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Attention!"
                                                        message:@"This is a custom alert where the buttons are drawn via CoreGraphics. It looks really nice, huh?"];
    
    [alertView addAlertButtonWithTitle:@"Cancel"
                                  type:SIAlertViewButtonTypeDanger
                               handler:^(SIAlertView *alertView) {
                                   NSLog(@"Cancel Clicked");
                               }];
    [alertView addAlertButtonWithTitle:@"OK"
                                  type:SIAlertViewButtonTypeOK
                               handler:^(SIAlertView *alertView) {
                                   NSLog(@"OK Clicked");
                               }];
    
    alertView.titleColor = [UIColor colorWithHue:3.0f/360.0f saturation:0.76f brightness:0.88f alpha:1.0f];
    alertView.messageColor = [UIColor colorWithWhite:0.35f alpha:0.8f];
    alertView.messageFont = [UIFont systemFontOfSize:16.0f];
    alertView.cornerRadius = 5.0f;
    alertView.buttonFont = [UIFont boldSystemFontOfSize:16.0f];
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
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:nil message:@"Message3"];
    
    [alertView addAlertButtonWithTitle:@"Cancel"
                                  type:SIAlertViewButtonTypeCancelDefault
                               handler:^(SIAlertView *alertView) {
                                   NSLog(@"Cancel Clicked");
                               }];
    [alertView addAlertButtonWithTitle:@"OK"
                                  type:SIAlertViewButtonTypeOKDefault
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

@end
