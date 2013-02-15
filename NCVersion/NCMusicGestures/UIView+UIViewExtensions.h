//
//  UIView+UIViewExtensions.h
//
//  Created by Pat Sluth on 2012-11-12.
//

#import <UIKit/UIKit.h>

@interface UIView(UIViewExtensions)

+ (void)setOrigin:(UIView *)v newOrigin:(CGPoint)newOrigin;
+ (void)setOriginX:(UIView *)v newOrigin:(CGFloat)newOrigin;
+ (void)setUpperRightOriginX:(UIView *)v newOrigin:(CGFloat)newOrigin;
+ (void)setLowerRightOriginX:(UIView *)v newOrigin:(CGFloat)newOrigin;
+ (void)setOriginY:(UIView *)v newOrigin:(CGFloat)newOrigin;
+ (void)setSize:(UIView *)v newSize:(CGSize)newSize;
+ (void)setSizeX:(UIView *)v newSize:(CGFloat)newSize;
+ (void)setSizeY:(UIView *)v newSize:(CGFloat)newSize;
+ (void)setCenterX:(UIView *)v newCenter:(float)newCenter;
+ (void)setCenterY:(UIView *)v newCenter:(float)newCenter;

@end
