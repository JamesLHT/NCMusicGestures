//
//  NCMusicGesturesHeaderPageOne.h
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NCMusicGesturesHeaderPageOne : UIView

@property (strong, nonatomic) UILabel *songTotalTime;

- (void)startUpdateSongPlaybackTimeTimer;
- (void)stopUpdateSongPlaybackTimeTimer;
- (void)checkSongTime;

- (void)reset;

@end
