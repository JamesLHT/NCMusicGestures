//
//  NCMusicGesturesHeaderPageOne.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "NCMusicGesturesHeaderPageOne.h"
#import "NCMusicGesturesView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+UIViewExtensions.h"
#import "StringFormatter.h"
#import "UISliderCustom.h"

#define LABEL_WIDTH 60
#define TIMELINE_SCRUBBER_X_PADDING 5

@interface NCMusicGesturesHeaderPageOne()

@property (strong, nonatomic) UILabel *songCurrentTime;
@property (strong, nonatomic) UISliderCustom *timelineScrubber;

@property (strong, nonatomic) NSTimer *updateSongPlaybackTimeTimer;

@property (assign, nonatomic) MPMusicPlayerController *ipod;

@end

@implementation NCMusicGesturesHeaderPageOne

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.songCurrentTime = [self createBasicLabel];
        self.songCurrentTime.textAlignment = NSTextAlignmentCenter;
        self.songCurrentTime.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.songCurrentTime];
        [UIView setSize:self.songCurrentTime newSize:CGSizeMake(LABEL_WIDTH, frame.size.height)];
        self.songCurrentTime.text = @"0:00";
        
        self.songTotalTime = [self createBasicLabel];
        self.songTotalTime.textAlignment = NSTextAlignmentCenter;
        self.songTotalTime.adjustsFontSizeToFitWidth = YES;
        [self addSubview:self.songTotalTime];
        [UIView setSize:self.songTotalTime newSize:CGSizeMake(LABEL_WIDTH, frame.size.height)];
        [UIView setUpperRightOriginX:self.songTotalTime newOrigin:self.frame.size.width];
        self.songTotalTime.text = @"0:00";
        
        self.timelineScrubber = [[UISliderCustom alloc] init];
        self.timelineScrubber.minimumTrackTintColor = [UIColor whiteColor];
        self.timelineScrubber.maximumTrackTintColor = [UIColor grayColor];
        [self addSubview:self.timelineScrubber];
        [UIView setSize:self.timelineScrubber newSize:CGSizeMake(self.frame.size.width -
                                                                 (LABEL_WIDTH * 2) -
                                                                 (TIMELINE_SCRUBBER_X_PADDING * 2),
                                                                 25)];
        [UIView setOriginX:self.timelineScrubber newOrigin:LABEL_WIDTH + TIMELINE_SCRUBBER_X_PADDING];
        [UIView setCenterY:self.timelineScrubber newCenter:self.frame.size.height / 2];
        [self.timelineScrubber addTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
    }
    return self;
}

- (MPMusicPlayerController *)ipod
{
    if (!_ipod){
        _ipod = [MPMusicPlayerController iPodMusicPlayer];
    }
    return _ipod;
}


- (void)onTimelineValueChange:(UISlider *)slider
{
    NSInteger currentItemLength = [[self.ipod.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    NSInteger newPlaybackTime = currentItemLength * slider.value;
    
    if (newPlaybackTime != self.ipod.currentPlaybackTime){
        self.ipod.currentPlaybackTime = newPlaybackTime;
        self.songCurrentTime.text = [StringFormatter formattedStringForDurationHMS:newPlaybackTime];
    }
}

- (void)startUpdateSongPlaybackTimeTimer
{
    if (!self.updateSongPlaybackTimeTimer){
        self.updateSongPlaybackTimeTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                                            target:self
                                                                          selector:@selector(checkSongTime)
                                                                          userInfo:nil
                                                                           repeats:YES];
    }
}

- (void)stopUpdateSongPlaybackTimeTimer
{
    if (self.updateSongPlaybackTimeTimer){
        [self.updateSongPlaybackTimeTimer invalidate];
        self.updateSongPlaybackTimeTimer = nil;
        [self.updateSongPlaybackTimeTimer release];
    }
}

- (void)checkSongTime
{
    if (self.timelineScrubber.isTracking){
        return;
    }
    
    if (self.ipod.currentPlaybackTime <= 0){
        self.songCurrentTime.text = @"0:00";
    } else {
        self.songCurrentTime.text = [StringFormatter formattedStringForDurationHMS:self.ipod.currentPlaybackTime];
    }
    
    NSInteger currentItemLength = [[self.ipod.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    float currentPlaybackPercentage = self.ipod.currentPlaybackTime / currentItemLength;
    self.timelineScrubber.value = currentPlaybackPercentage;
}

- (void)reset
{
    self.songCurrentTime.text = @"0:00";
    self.songTotalTime.text = @"0:00";
}

- (UILabel *)createBasicLabel
{
    UILabel *l = [[UILabel alloc] init];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor whiteColor];
    
    return l;
}

- (void)dealloc
{
    [self stopUpdateSongPlaybackTimeTimer];
    
    [self.songCurrentTime release];
    [self.songTotalTime release];
    [self.timelineScrubber removeTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.timelineScrubber release];
    
    [self.ipod release];
    
    [super dealloc];
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
