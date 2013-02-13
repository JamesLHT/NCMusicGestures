//
//  UIView+UIViewExtensions.m
//  FoxSports
//
//  Created by Pat Sluth on 2012-11-12.
//  Copyright (c) 2012 Übermind. All rights reserved.
//

#import "UIView+UIViewExtensions.h"

@implementation UIView(UIViewExtensions)

+ (void)setOrigin:(UIView *)v newOrigin:(CGPoint)newOrigin
{
    v.frame = CGRectMake(newOrigin.x, newOrigin.y, v.frame.size.width, v.frame.size.height);
}

+ (void)setOriginX:(UIView *)v newOrigin:(CGFloat)newOrigin
{
    v.frame = CGRectMake(newOrigin, v.frame.origin.y, v.frame.size.width, v.frame.size.height);
}

+ (void)setUpperRightOriginX:(UIView *)v newOrigin:(CGFloat)newOrigin
{
    v.frame = CGRectMake(newOrigin - v.frame.size.width, v.frame.origin.y, v.frame.size.width, v.frame.size.height);
}

+ (void)setOriginY:(UIView *)v newOrigin:(CGFloat)newOrigin
{
    v.frame = CGRectMake(v.frame.origin.x, newOrigin, v.frame.size.width, v.frame.size.height);
}

+ (void)setSize:(UIView *)v newSize:(CGSize)newSize
{
    v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, newSize.width, newSize.height);
}

+ (void)setSizeX:(UIView *)v newSize:(CGFloat)newSize
{
    v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, newSize, v.frame.size.height);
}

+ (void)setSizeY:(UIView *)v newSize:(CGFloat)newSize
{
     v.frame = CGRectMake(v.frame.origin.x, v.frame.origin.y, v.frame.size.width, newSize);
}

+ (void)setCenterX:(UIView *)v newCenter:(float)newCenter
{
    v.center = CGPointMake(newCenter, v.center.y);
}

+ (void)setCenterY:(UIView *)v newCenter:(float)newCenter
{
    v.center = CGPointMake(v.center.x, newCenter);
}

@end
