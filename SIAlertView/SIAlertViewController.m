//
//  SIAlertViewController.m
//  SIAlertView
//

#import "SIAlertViewController.h"
#import "SIAlertView.h"

@interface SIAlertViewController ()

@end



@implementation SIAlertViewController


#pragma mark - View lifecycle
#pragma mark - View lifecycle
- (void)loadView
{
    [super loadView];
    self.view = self.alertView;

}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.alertView setup];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    NSLog(@"** didReceiveMemoryWarning **");
}

#pragma mark - View rotation


- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.alertView resetTransition];
    [self.alertView invalidateLayout];
}

@end
