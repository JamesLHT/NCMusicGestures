//
//  NCMusicGesturesView.h
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

#define VIEW_HEADER_HEIGHT 50
#define VIEW_WIDTH 316
#define VIEW_HEIGHT 100

@interface NCMusicGesturesView : UIView <UIScrollViewDelegate>

+ (MPMusicPlayerController *)ipod;

@end
