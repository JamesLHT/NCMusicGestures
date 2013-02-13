//
//  StringFormatter.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "StringFormatter.h"

@implementation StringFormatter

+ (NSString *)formattedStringForDurationMS:(NSTimeInterval)duration
{
    NSInteger minutes = floor(duration/60);
    NSInteger seconds = round(duration - minutes * 60);
    return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
}

+ (NSString *)formattedStringForDurationHMS:(NSTimeInterval)duration
{
    NSInteger ti = (NSInteger)duration;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    NSInteger hours = (ti / 3600);
    
    if (hours <= 0){
        return [self formattedStringForDurationMS:duration];
    } else if (hours < 9){
        return [NSString stringWithFormat:@"%2i:%02i:%02i", hours, minutes, seconds];
    } else {
        return [NSString stringWithFormat:@"%02i:%02i:%02i", hours, minutes, seconds];
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
