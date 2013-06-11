SIAlertView
=============

A UIAlertView subclass with block syntax and fancy transition styles. As seen in [Grid Diary](http://griddiaryapp.com/).

## Preview

![SIAlertView Screenshot](https://github.com/jessesquires/SIAlertView/raw/master/screenshot.png)

## Features

- use window to present
- happy with rotation
- block syntax
- styled transitions
- queue support
- UIAppearance support

## Installation

### Cocoapods(Recommended)

1. Add `pod 'SIAlertView'` to your Podfile.
2. Run `pod install`

### Manual

1. Add all files under `SIAlertView/SIAlertView` to your project
2. Add `QuartzCore.framework` to your project

## Requirements

- iOS 6.0+
- ARC

## Examples

````objective-c

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

````

## Credits

SIAlertView was created by [Sumi Interactive](https://github.com/Sumi-Interactive) in the development of [Grid Diary](http://griddiaryapp.com/).

## License

SIAlertView is available under the MIT license. See the LICENSE file for more info.
