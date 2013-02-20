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
#define VIEW_WIDTH_PORTRAIT [[UIScreen mainScreen] bounds].size.width
#define VIEW_WIDTH_LANDSCAPE [[UIScreen mainScreen] bounds].size.height
#define VIEW_HEIGHT 100

@interface NCMusicGesturesView : UIView <UIScrollViewDelegate, UIAlertViewDelegate>

+ (MPMusicPlayerController *)ipod;

@end
