//
//  UIImage.m
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-02-14.
//
//

#import "UIImage+UIImageExtensions.h"

@implementation UIImage(UIImageExtensions)

+ (UIImage *)imageFromBundleWithName:(NSString *)imageName
{
    NSString *fullImagePath = [NSString stringWithFormat:@"%@%@",
                               @"/System/Library/WeeAppPlugins/NCMusicGestures.bundle/", imageName];
    return [UIImage imageWithContentsOfFile:fullImagePath];
}

@end