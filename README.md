SIAlertView
=============

An UIAlertView replacement with block syntax and fancy transition styles. As seen in [Grid Diary](http://griddiaryapp.com/).

## Preview

![SIAlertView Screenshot](https://github.com/Sumi-Interactive/SIAlertView/raw/master/screenshot.png)

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

- iOS 5.0 and greater
- ARC

(If you are having any problems, just select your project -> Build Phases -> Compile Sources, double-click the SIAlertView and add `-fobjc-arc`)

## Examples

**Code:**

```objc
SIAlertView *alertView = [[SIAlertView alloc] initWithTitle:@"SIAlertView" andMessage:@"Sumi Interactive"];

[alertView addButtonWithTitle:@"Button1"
                         type:SIAlertViewButtonTypeDefault
                      handler:^(SIAlertView *alert) {
                          NSLog(@"Button1 Clicked");
                      }];
[alertView addButtonWithTitle:@"Button2"
                         type:SIAlertViewButtonTypeDestructive
                      handler:^(SIAlertView *alert) {
                          NSLog(@"Button2 Clicked");
                      }];
[alertView addButtonWithTitle:@"Button3"
                         type:SIAlertViewButtonTypeCancel
                      handler:^(SIAlertView *alert) {
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

alertView.transitionStyle = SIAlertViewTransitionStyleBounce;

[alertView show];
```

## Credits

SIAlertView was created by [Sumi Interactive](https://github.com/Sumi-Interactive) in the development of [Grid Diary](http://griddiaryapp.com/).

## License

SIAlertView is available under the MIT license. See the LICENSE file for more info.
