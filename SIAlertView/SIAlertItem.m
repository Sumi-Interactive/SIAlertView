//
//  SIAlertItem.m
//  SIAlertView
//
//
//  Created by Kevin Cao on 5/30/13.
//  Core Graphics integration by Christopher Constable.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertItem.h"

@interface SIAlertItem ()

@end

@implementation UIColor (LightAndDark)

- (UIColor *)lighterColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:MIN(b * 1.1, 1.0)
                               alpha:a];
    return nil;
}

- (UIColor *)darkerColor
{
    float h, s, b, a;
    if ([self getHue:&h saturation:&s brightness:&b alpha:&a])
        return [UIColor colorWithHue:h
                          saturation:s
                          brightness:b * 0.9
                               alpha:a];
    return nil;
}

@end

@implementation SIAlertItem

- (UIImage *)imageForButton
{
    CGSize buttonSize = CGSizeMake(9, 9);
    UIGraphicsBeginImageContext(buttonSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* color = [self.buttonColor darkerColor];
    UIColor* color2 = self.buttonColor;
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, 9, 9) cornerRadius: 5];
    [color2 setFill];
    [roundedRectanglePath fill];
    [color setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];

    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* image = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);
    
    UIGraphicsEndImageContext();
    
    return image;
}

- (UIImage *)imageForButtonHighlighted
{
    CGSize buttonSize = CGSizeMake(9, 9);
    UIGraphicsBeginImageContext(buttonSize);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor* color = [[self.buttonColor darkerColor] darkerColor];
    UIColor* color2 = [self.buttonColor darkerColor];
    
    //// Rounded Rectangle Drawing
    UIBezierPath* roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect: CGRectMake(0, 0, 9, 9) cornerRadius: 5];
    [color2 setFill];
    [roundedRectanglePath fill];
    [color setStroke];
    roundedRectanglePath.lineWidth = 1;
    [roundedRectanglePath stroke];
    
    CGImageRef imgRef = CGBitmapContextCreateImage(context);
    UIImage* image = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);
    
    UIGraphicsEndImageContext();
    
    return image;
}

@end
