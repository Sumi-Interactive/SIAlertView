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
    [[SIAlertView appearance] setMessageFont:[UIFont systemFontOfSize:13]];
    [[SIAlertView appearance] setTitleColor:[UIColor greenColor]];
    [[SIAlertView appearance] setMessageColor:[UIColor purpleColor]];
    [[SIAlertView appearance] setCornerRadius:12];
    [[SIAlertView appearance] setShadowRadius:20];
   #endif
}

#pragma mark - Actions

- (IBAction)alert1:(id)sender
{
    SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"Title1" message:@"Count down"];
    [alertView addAlertButtonWithTitle:@"Button1" color:[UIColor redColor] handler:^(SIAlertView *alertView) {
        NSLog(@"Button1 Clicked");
    } enabled:YES];

    
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
