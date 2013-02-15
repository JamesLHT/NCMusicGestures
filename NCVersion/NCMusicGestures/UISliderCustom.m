//
//  UISliderCustom.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "UISliderCustom.h"

@implementation UISliderCustom

- (CGRect)thumbRect
{
    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds
                                      trackRect:trackRect
                                          value:self.value];
    return thumbRect;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect thumbFrame = [self thumbRect];
    
    // check if the point is within the thumb
    if (CGRectContainsPoint(thumbFrame, point)){
       // NSLog(@"%@%@%@", NSStringFromCGRect(thumbFrame), @"___", NSStringFromCGPoint(point));
        return [super hitTest:point withEvent:event];
    } else {
        return [[self superview] hitTest:point withEvent:event];
    }
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
