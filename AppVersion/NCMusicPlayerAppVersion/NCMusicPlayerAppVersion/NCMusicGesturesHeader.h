//
//  NCMusicGesturesHeader.h
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-12.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface NCMusicGesturesHeader : UIView <UIScrollViewDelegate>

- (void)setInfoFromMPMediaItem:(MPMediaItem *)item animated:(BOOL)animated;

- (void)reset;

@end
