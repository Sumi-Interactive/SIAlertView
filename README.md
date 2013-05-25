##SIAlertView

An UIAlertView replacement with block syntax and fancy transition styles. As seen in [Grid Diary](http://griddiaryapp.com/).

![SIAlertView Screenshot](https://github.com/Sumi-Interactive/SIAlertView/raw/master/screenshot.png)

##FEATURES

- use window to present
- happy with rotation
- block syntax
- styled transitions
- queue support
- UIAppearance support

##HOW TO USE

**Required:** iOS 6+, ARC

1. Add all files under `SIAlertView/SIAlertView` to your project
2. Add `QuartzCore.framework` to your project
3. Add `#import "SIAlertView.h"` before using it

##EXAMPLES

**Code:**

```
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

alertView.willShowHandler = ^(SIAlertView *alert) {
    NSLog(@"%@, willShowHandler", self);
};
alertView.didShowHandler = ^(SIAlertView *alert) {
    NSLog(@"%@, didShowHandler", self);
};
alertView.willDismissHandler = ^(SIAlertView *alert) {
    NSLog(@"%@, willDismissHandler", self);
};
alertView.didDismissHandler = ^(SIAlertView *alert) {
    NSLog(@"%@, didDismissHandler", self);
};

alertView.transitionStyle = SIAlertViewTransitionStyleBounce;

[alertView show];
```

##LICENSE

SIAlertView is available under the MIT license. See the LICENSE file for more info.