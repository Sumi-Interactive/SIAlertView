//
//  SIAlertBackgroundWindow.m
//  SIAlertView
//


#import "SIAlertBackgroundWindow.h"

const UIWindowLevel UIWindowLevelSIAlert = 1996.0;  // don't overlap system's alert
const UIWindowLevel UIWindowLevelSIAlertBackground = 1985.0; // below the alert window

@interface SIAlertBackgroundWindow ()

@property (nonatomic, assign) SIAlertViewBackgroundStyle style;

@end



@implementation SIAlertBackgroundWindow

#pragma mark - Initialization

- (id)initWithFrame:(CGRect)frame andStyle:(SIAlertViewBackgroundStyle)style
{
    self = [super initWithFrame:frame];
    if(self) {
        _style = style;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelSIAlertBackground;
    }
    return self;
}

#pragma mark - Drawing

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();

    switch (self.style) {
        case SIAlertViewBackgroundStyleGradient:
        {
            size_t locationsCount = 2;
            CGFloat locations[2] = {0.0f, 1.0f};
            CGFloat colors[8] = {0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.0f, 0.75f};
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CGGradientRef gradient = CGGradientCreateWithColorComponents(colorSpace, colors, locations, locationsCount);
            CGColorSpaceRelease(colorSpace);
            
            CGPoint center = CGPointMake(self.bounds.size.width / 2, self.bounds.size.height / 2);
            CGFloat radius = MIN(self.bounds.size.width, self.bounds.size.height) ;
            CGContextDrawRadialGradient (context, gradient, center, 0, center, radius, kCGGradientDrawsAfterEndLocation);
            CGGradientRelease(gradient);
        }
            break;
        case SIAlertViewBackgroundStyleSolid:
        {
            
            [[UIColor colorWithWhite:0 alpha:0.5] set];
            CGContextFillRect(context, self.bounds);

        }
            break;
        case SIAlertViewBackgroundStyleClear:
        {
            [[UIColor clearColor] set];
            CGContextFillRect(context, self.bounds);
        }
    }

    [super drawRect:rect];
}

@end
