//
//  StringFormatter.h
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface StringFormatter : NSObject

+ (NSString *)formattedStringForDurationMS:(NSTimeInterval)duration;
+ (NSString *)formattedStringForDurationHMS:(NSTimeInterval)duration;

@end
