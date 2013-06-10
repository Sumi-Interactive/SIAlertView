//
//  SIAlertButton.m
//  SIAlertView
//
//  Created by Kevin Cao on 13-4-29.
//  Copyright (c) 2013年 Sumi Interactive. All rights reserved.
//

#import "SIAlertButton.h"

@implementation SIAlertButton

+ (SIAlertButton *)alertButtonWithTitle:(NSString *)aTitle
                                   type:(SIAlertViewButtonType)aType
                                 action:(SIAlertViewHandler)anAction
                                   font:(UIFont *)aFont
                                    tag:(NSInteger)aTag
{
    SIAlertButton *button = [SIAlertButton buttonWithType:UIButtonTypeCustom];
	button.tag = aTag;
	button.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    button.titleLabel.font = aFont;
	[button setTitle:aTitle forState:UIControlStateNormal];
    
	UIImage *normalImage = nil;
	UIImage *highlightedImage = nil;
	
    switch (aType) {
		case SIAlertViewButtonTypeCancel:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-cancel"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-cancel-d"];
			[button setTitleColor:[UIColor colorWithWhite:0.3f alpha:1.0f] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.3f alpha:0.8f] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDestructive:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-destructive-d"];
            [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:1.0f alpha:0.8f] forState:UIControlStateHighlighted];
			break;
		case SIAlertViewButtonTypeDefault:
		default:
			normalImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default"];
			highlightedImage = [UIImage imageNamed:@"SIAlertView.bundle/button-default-d"];
			[button setTitleColor:[UIColor colorWithWhite:0.4f alpha:1.0f] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor colorWithWhite:0.4f alpha:0.8f] forState:UIControlStateHighlighted];
			break;
	}
    
	CGFloat hInset = floorf(normalImage.size.width / 2.0f);
	CGFloat vInset = floorf(normalImage.size.height / 2.0f);
	UIEdgeInsets insets = UIEdgeInsetsMake(vInset, hInset, vInset, hInset);
	normalImage = [normalImage resizableImageWithCapInsets:insets];
	highlightedImage = [highlightedImage resizableImageWithCapInsets:insets];
	[button setBackgroundImage:normalImage forState:UIControlStateNormal];
	[button setBackgroundImage:highlightedImage forState:UIControlStateHighlighted];
    
    return button;
}

@end
