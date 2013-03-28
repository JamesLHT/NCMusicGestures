//
//  NCMusicGesturesView.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "NCMusicGesturesView.h"
#import "NCMusicGesturesController.h"

#import "UIImage+UIImageExtensions.h"
#import "UIView+UIViewExtensions.h"
#import "StringFormatter.h"
#import "UISliderCustom.h"
#import "MarqueeLabel.h"

#import <MediaPlayer/MediaPlayer.h>
#import <Social/Social.h>

#define ALBUM_ART_ANIM_TIME 0.5
#define ALBUM_ART_PADDING 10
#define ALBUM_ART_SIZE 85
#define ICLOUD_IMAGE_SIZE 20

#define BACKGROUND_IMAGE_DEFAULT [UIImage imageFromBundleWithName:@"WeeAppBackground.png"]

#define IMAGE_DISC [UIImage imageFromBundleWithName:@"cddisc.png"]
#define IMAGE_CLOUD [UIImage imageFromBundleWithName:@"white_cloud.png"]

//header
//header timeline view
#define HEADER_SONG_TIME_LABEL_WIDTH 65
#define HEADER_TIMELINE_SCRUBBER_X_PADDING 5
#define HEADER_PAGE_DOT_INDICATOR_OFFSET 6

//header button view
/*#define IMAGE_SHUFFLE_ON [UIImage imageFromBundleWithName:@"white_shuffle.png"]
#define IMAGE_SHUFFLE_OFF [UIImage imageFromBundleWithName:@"grey_shuffle.png"]

#define IMAGE_REPEAT_ALL [UIImage imageFromBundleWithName:@"white_repeat.png"]
#define IMAGE_REPEAT_ONE [UIImage imageFromBundleWithName:@"white_repeat_one.png"]
#define IMAGE_REPEAT_OFF [UIImage imageFromBundleWithName:@"grey_repeat.png"]*/

#define IMAGE_TWITTER_OFF [UIImage imageFromBundleWithName:@"grey_twitter.png"]
#define IMAGE_TWITTER_ON [UIImage imageFromBundleWithName:@"white_twitter.png"]

#define IMAGE_FACEBOOK_OFF [UIImage imageFromBundleWithName:@"grey_facebook.png"]
#define IMAGE_FACEBOOK_ON [UIImage imageFromBundleWithName:@"white_facebook.png"]

#define IMAGE_DONATE [UIImage imageFromBundleWithName:@"white_donate.png"]

@interface NCMusicGesturesView()

typedef enum  {
    None,
    Stop,
    Play,
    Pause,
    SkipToNext,
    SkipToPrevious,
    SeekForward,
    SeekBackwards
} IPOD_ACTION_TO_PERFORM;


//base
@property (readwrite, nonatomic) IPOD_ACTION_TO_PERFORM ipodActionToPerformOnScrollViewDeceleration;

@property (retain, nonatomic) UIImageView *background;
@property (retain, nonatomic) UIScrollView *baseScrollView;

@property (retain, nonatomic) UIImageView *albumArt;
@property (retain, nonatomic) UIImageView *albumIsOniCloud;
@property (retain, nonatomic) MarqueeLabel *songTitle;
@property (retain, nonatomic) MarqueeLabel *songArtist;
@property (retain, nonatomic) MarqueeLabel *songAlbum;

@property (retain, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (retain, nonatomic) UILongPressGestureRecognizer *longHoldGestureRecognizer;

//header
@property (retain, nonatomic) UIScrollView *headerScrollView;
@property (retain, nonatomic) UIPageControl *headerScrollViewPageControl;

@property (retain, nonatomic) UIView *headerSongTimelineView;
@property (retain, nonatomic) UILabel *songCurrentTime;
@property (retain, nonatomic) UILabel *songTotalTime;
@property (retain, nonatomic) UISliderCustom *timelineScrubber;
@property (retain, nonatomic) NSTimer *updateSongPlaybackTimeTimer;

@property (retain, nonatomic) UIView *headerButtonView;
//@property (strong, nonatomic) UIButton *shuffleButton;
//@property (strong, nonatomic) UIButton *repeatButton;
@property (retain, nonatomic) UIButton *twitterButton;
@property (retain, nonatomic) UIButton *facebookButton;
@property (retain, nonatomic) UIButton *donateButton;

@property (assign, nonatomic) MPMusicPlayerController *ipod;

@end

@implementation NCMusicGesturesView

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        self.view.clipsToBounds = YES;
        
        self.ipod = [MPMusicPlayerController iPodMusicPlayer];
        //[self.ipod setShuffleMode:MPMusicShuffleModeOff];
        //[self.ipod setRepeatMode:MPMusicRepeatModeNone];
        
        
        
        UIImage *bg = [BACKGROUND_IMAGE_DEFAULT
                       stretchableImageWithLeftCapWidth:BACKGROUND_CAP_VALUE
                       topCapHeight:BACKGROUND_CAP_VALUE];
        
        [self updateBackgroundImage:bg];
        
        self.ipodActionToPerformOnScrollViewDeceleration = None;
        
        //base
        [self setupBase];
        //header
        [self setupHeader];
    }
    return self;
}

- (void)onViewDidAppear
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(onViewDidAppear) withObject:nil waitUntilDone:NO];
        return;
    }
    
    [self setupiPodListeners];
    
    self.background.frame = self.view.frame;
    [UIView setOrigin:self.background newOrigin:CGPointZero];
    
    [self setupBase];
    
    NSInteger currentPage = (self.headerScrollViewPageControl) ? self.headerScrollViewPageControl.currentPage : 0;
    
    [self setupHeader];
    
    self.headerScrollView.contentOffset = CGPointMake(self.headerScrollView.frame.size.width * (currentPage), 0);
    
    [self startUpdateSongPlaybackTimeTimer];
}

- (void)onViewDidDissappear
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(onViewDidDissappear) withObject:nil waitUntilDone:NO];
        return;
    }
    
    //[self cleanupiPodListeners];
    
    [self stopUpdateSongPlaybackTimeTimer];
}


#pragma mark Gesture Recognizer

- (void)onTap:(UITapGestureRecognizer *)tap
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(onTap:) withObject:tap waitUntilDone:NO];
        return;
    }
    
    if (tap.state == UIGestureRecognizerStateEnded){
        if (self.ipod.playbackState == MPMusicPlaybackStatePaused ||
            self.ipod.playbackState == MPMusicPlaybackStateStopped){
            if (self.ipod.nowPlayingItem){
                [self.ipod play];
                [self performPlayPauseAnimation];
            } else { //nothing playing, so we will play all
                [self playAllSongs];
            }
        } else if (self.ipod.playbackState == MPMusicPlaybackStatePlaying){
            [self.ipod pause];
            [self performPlayPauseAnimation];
        }
    }
}

- (void)onLongHold:(UILongPressGestureRecognizer *)hold
{
    if (hold.state == UIGestureRecognizerStateBegan){
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"music://"]];
    }
}

- (void)performPlayPauseAnimation
{
    [UIView animateWithDuration:0.1 animations:^{
        self.baseScrollView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.1 animations:^{
            self.baseScrollView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:nil];
    }];
}

#pragma mark iPod

- (void)playAllSongs
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(playAllSongs) withObject:nil waitUntilDone:NO];
        return;
    }
    
    MPMediaQuery *everything = [[MPMediaQuery alloc] init];
    
    NSArray *itemsFromGenericQuery = [everything items];
    MPMediaItemCollection *collection = [[MPMediaItemCollection alloc] initWithItems:itemsFromGenericQuery];
    [self.ipod setQueueWithItemCollection:collection];
    [self.ipod play];
}

- (void)oniPodItemChanged:(id)notification
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(oniPodItemChanged) withObject:notification waitUntilDone:NO];
        return;
    }
    
    self.albumIsOniCloud.hidden = YES;
    
    MPMediaItem *item = self.ipod.nowPlayingItem;
    
    [self setInfoFromMPMediaItem:item animated:YES];
    [self checkSongTime];
}

- (void)oniPodStateChanged:(id)notification
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(oniPodStateChanged) withObject:notification waitUntilDone:NO];
        return;
    }
    
    switch (self.ipod.playbackState) {
        case MPMusicPlaybackStateStopped:
            [self stopUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStatePlaying:
            [self startUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStatePaused:
            [self stopUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStateInterrupted:
            [self stopUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStateSeekingForward:
            [self startUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStateSeekingBackward:
            [self startUpdateSongPlaybackTimeTimer];
            break;
            
        default:
            break;
    }
}

- (void)setInfoFromMPMediaItem:(MPMediaItem *)item animated:(BOOL)animated
{
    if (item){
        //[self.header setInfoFromMPMediaItem:item animated:animated];
        
        self.songTitle.text = [item valueForProperty:MPMediaItemPropertyTitle];
        self.songArtist.text = [item valueForProperty:MPMediaItemPropertyArtist];
        self.songAlbum.text = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        
        MPMediaItemArtwork *itemArtwork = [item valueForProperty:MPMediaItemPropertyArtwork];
        [self setAlbumArtToNewImage:[itemArtwork imageWithSize:self.albumArt.bounds.size]
                           animated:animated
                     halfCompletion:nil
                         completion:^{
                             self.albumIsOniCloud.hidden = ![[item valueForProperty:MPMediaItemPropertyIsCloudItem] boolValue];
                         }];
        
    } else {
        
        [self resetHeader];
        
        self.songTitle.text = @"";
        self.songArtist.text = @"";
        self.songAlbum.text = @"";
        
        [self setAlbumArtToNewImage:nil
                           animated:animated
                     halfCompletion:nil
                         completion:nil];
    }
}

- (void)setAlbumArtToNewImage:(UIImage *)image
                     animated:(BOOL)animated
               halfCompletion:(void (^)())halfCompletion
                   completion:(void (^)())completion
{
    UIImage *newAlbumArtImage = (image) ? image : IMAGE_DISC;
    
    if (animated){
        
        [UIView animateWithDuration:ALBUM_ART_ANIM_TIME / 2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            self.albumArt.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }completion:^(BOOL finished){
            
            if (halfCompletion){
                halfCompletion();
            }
            
            [UIView animateWithDuration:ALBUM_ART_ANIM_TIME / 2
                                  delay:0
                                options:UIViewAnimationOptionCurveEaseIn
                             animations:^{
                self.albumArt.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }completion:^(BOOL finished){
                if (completion){
                    completion();
                }
            }];
        }];
        
        [UIView transitionWithView:self.albumArt duration:ALBUM_ART_ANIM_TIME options:UIViewAnimationOptionTransitionFlipFromRight
                        animations:^{
                            self.albumArt.image = newAlbumArtImage;
                            [self updateBackgroundImage:newAlbumArtImage];
                        } completion:nil];
    } else {
        self.albumArt.image = newAlbumArtImage;
    }
}

- (void)updateBackgroundImage:(UIImage *)image
{
    //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL useAlbumArt = NO;// [defaults boolForKey:@"useAlbumArtAsBackground"];
    
    if (!self.background){
        self.background = [[UIImageView alloc] initWithFrame:self.view.frame];
		[self.view addSubview:self.background];
    }
    
    [UIView setOrigin:self.background newOrigin:CGPointZero];
    
    if (!useAlbumArt || !image){
        self.background.backgroundColor = [UIColor clearColor];
        UIImage *bg = [BACKGROUND_IMAGE_DEFAULT
                       stretchableImageWithLeftCapWidth:BACKGROUND_CAP_VALUE
                       topCapHeight:BACKGROUND_CAP_VALUE];
        self.background.image = bg;
        
    } else {
        self.background.backgroundColor = [UIColor blackColor];
        self.background.contentMode = UIViewContentModeScaleAspectFill;
        self.background.image = image;
        self.background.alpha = 0.4;
    }
}

#pragma mark Header

- (void)onTimelineValueChange:(UISlider *)slider
{
    NSInteger currentItemLength = [[self.ipod.nowPlayingItem
                                    valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    NSInteger newPlaybackTime = currentItemLength * slider.value;
    
    if (newPlaybackTime != self.ipod.currentPlaybackTime){
        self.ipod.currentPlaybackTime = newPlaybackTime;
        self.songCurrentTime.text = [StringFormatter formattedStringForDurationHMS:newPlaybackTime];
        NSInteger songTimeLeft = currentItemLength - newPlaybackTime;
        
        if (songTimeLeft < 0){
            songTimeLeft = 0;
        }
        
        self.songTotalTime.text = [StringFormatter formattedStringForDurationHMS:songTimeLeft];
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
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(checkSongTime) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (self.timelineScrubber.isTracking){
        return;
    }
    
    MPMediaItem *current = self.ipod.nowPlayingItem;
    
    if (current){
        NSNumber *songTime = (NSNumber *)[current valueForKey:MPMediaItemPropertyPlaybackDuration];
        NSInteger songTimeLeft = [songTime integerValue] - self.ipod.currentPlaybackTime;
        
        if (songTimeLeft < 0){
            songTimeLeft = 0;
        }
        
        if (songTime){
            self.songTotalTime.text = [StringFormatter
                                       formattedStringForDurationHMS:songTimeLeft];
        } else {
            self.songTotalTime.text = @"0:00";
        }
    } else {
        self.songTotalTime.text = @"0:00";
    }
    
    if (self.ipod.playbackState == MPMusicPlaybackStatePlaying ||
        self.ipod.playbackState == MPMusicPlaybackStateSeekingBackward ||
        self.ipod.playbackState == MPMusicPlaybackStateSeekingForward){
        
        NSInteger time = self.ipod.currentPlaybackTime;
        
        if (time < 0){
            time = 0;
        }
        
        self.songCurrentTime.text = [StringFormatter formattedStringForDurationHMS:time];
        
        NSInteger currentItemLength = [[self.ipod.nowPlayingItem
                                        valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
        float currentPlaybackPercentage = self.ipod.currentPlaybackTime / currentItemLength;
        self.timelineScrubber.value = currentPlaybackPercentage;
        
    } else {
        self.songCurrentTime.text = @"0:00";
        self.timelineScrubber.value = 0.0;
    }
}

/*
- (void)shuffleButtonClicked
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(shuffleButtonClicked) withObject:nil waitUntilDone:NO];
        return;
    }
    
    switch (self.ipod.shuffleMode) {
        case MPMusicShuffleModeOff:
            [self.ipod setShuffleMode:MPMusicShuffleModeSongs];
            break;
            
        case MPMusicShuffleModeSongs:
            [self.ipod setShuffleMode:MPMusicShuffleModeOff];
            break;
            
        case MPMusicShuffleModeDefault:
            [self.ipod setShuffleMode:MPMusicShuffleModeOff];
            break;
            
        case MPMusicShuffleModeAlbums:
            [self.ipod setShuffleMode:MPMusicShuffleModeOff];
            break;
            
        default:
            break;
    }
    
    [self updateShuffleButtonToCurrentState];
}

- (void)updateShuffleButtonToCurrentState
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(updateShuffleButtonToCurrentState) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (!self.ipod.playbackState == MPMusicPlaybackStatePlaying){
        switch (self.ipod.shuffleMode) {
            case MPMusicShuffleModeOff:
                [self.shuffleButton setImage:IMAGE_SHUFFLE_OFF forState:UIControlStateNormal];
                break;
                
            case MPMusicShuffleModeSongs:
                [self.shuffleButton setImage:IMAGE_SHUFFLE_ON forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
    } else {
        [self.shuffleButton setImage:IMAGE_SHUFFLE_ON forState:UIControlStateNormal];
    }
}

- (void)repeateButtonClicked
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(repeateButtonClicked) withObject:nil waitUntilDone:NO];
        return;
    }
    
    switch (self.ipod.repeatMode) {
        case MPMusicRepeatModeNone:
            [self.ipod setRepeatMode:MPMusicRepeatModeAll];
            break;
            
        case MPMusicRepeatModeAll:
            [self.ipod setRepeatMode:MPMusicRepeatModeOne];
            break;
            
        case MPMusicRepeatModeOne:
            [self.ipod setRepeatMode:MPMusicRepeatModeNone];
            break;
            
        case MPMusicShuffleModeDefault:
            [self.ipod setRepeatMode:MPMusicRepeatModeNone];
            break;
            
        default:
            break;
    }
    
    [self updateRepeatButtonToCurrentState];
}

- (void)updateRepeatButtonToCurrentState
{
    if (![NSThread isMainThread]){
        [self performSelectorOnMainThread:@selector(updateRepeatButtonToCurrentState) withObject:nil waitUntilDone:NO];
        return;
    }
    
    if (!self.ipod.playbackState == MPMusicPlaybackStatePlaying){
        switch (self.ipod.repeatMode) {
            case MPMusicRepeatModeDefault:
                [self.repeatButton setImage:IMAGE_REPEAT_ALL forState:UIControlStateNormal];
                break;
                
            case MPMusicRepeatModeNone:
                [self.repeatButton setImage:IMAGE_REPEAT_OFF forState:UIControlStateNormal];
                break;
                
            case MPMusicRepeatModeAll:
                [self.repeatButton setImage:IMAGE_REPEAT_ALL forState:UIControlStateNormal];
                break;
                
            case MPMusicRepeatModeOne:
                [self.repeatButton setImage:IMAGE_REPEAT_ONE forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
    } else {
        [self.repeatButton setImage:IMAGE_REPEAT_ALL forState:UIControlStateNormal];
    }
}*/

- (void)twitterButtonClicked
{
    [self updateTwitterButton];
    [self shareCurentSongWithServiceType:SLServiceTypeTwitter];
}

- (void)facebookButtonClicked
{
    [self updateFacbookButton];
    [self shareCurentSongWithServiceType:SLServiceTypeFacebook];
}

- (void)updateTwitterButton
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]){
        [self.twitterButton setImage:IMAGE_TWITTER_ON forState:UIControlStateNormal];
    } else {
        [self.twitterButton setImage:IMAGE_TWITTER_OFF forState:UIControlStateNormal];
    }
}

- (void)updateFacbookButton
{
    if ([SLComposeViewController isAvailableForServiceType:SLServiceTypeFacebook]){
        [self.facebookButton setImage:IMAGE_FACEBOOK_ON forState:UIControlStateNormal];
    } else {
        [self.facebookButton setImage:IMAGE_FACEBOOK_OFF forState:UIControlStateNormal];
    }
}

- (void)shareCurentSongWithServiceType:(NSString *)serviceType
{
    if ([SLComposeViewController isAvailableForServiceType:serviceType])
    {
        MPMediaItem *item = self.ipod.nowPlayingItem;
        
        if (item){
            NSString *songTitle = [item valueForProperty:MPMediaItemPropertyTitle];
            NSString *songArtist = [item valueForProperty:MPMediaItemPropertyArtist];
            
            MPMediaItemArtwork *itemArtwork = [item valueForProperty:MPMediaItemPropertyArtwork];
            UIImage *albumArtImage = [itemArtwork imageWithSize:itemArtwork.bounds.size];
            
            SLComposeViewController *composeVC = [SLComposeViewController
                                                              composeViewControllerForServiceType:serviceType];
            
            NSMutableString *message = [NSMutableString stringWithFormat:@"%@%@",
                                        @"I am listening to ", songTitle];
            
            if (songArtist){
                [message appendFormat:@"%@%@", @" by ", songArtist];
            }
            
            [composeVC setInitialText:message];
            
            if (albumArtImage){
                [composeVC addImage:albumArtImage];
            }
            
            [self presentViewController:composeVC animated:YES completion:nil];
            
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Item Playing"
                                                            message:@"Play a song and try again"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    }
    else
    {
        NSMutableString *message = [[NSMutableString alloc] initWithString:@"Sharing not configured"];
        
        if (serviceType == SLServiceTypeTwitter){
            [message appendString:@" for Twitter "];
        } else if (serviceType == SLServiceTypeFacebook){
            [message appendString:@" for Facebook "];
        }
        
        [message appendString:@"\nEnable in Settings app to use this feature"];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sharing"
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
}

- (void)donateButtonClicked
{
    NSString *message = @"Please support if you like this app!";
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Donate"
                                                    message:message
                                                   delegate:self
                                          cancelButtonTitle:@"No Thanks"
                                          otherButtonTitles:@"Donate", nil];
    [alert show];
    [alert release];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    if([title isEqualToString:@"Donate"])
    {
        NSURL *url = [[NSURL alloc]
                      initWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=pat%2esluth%40gmail%2ecom&lc=CA&item_name=Pat%20Sluth&no_note=0&currency_code=CAD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest"];
        [[UIApplication sharedApplication] openURL:url];
    }
}

#pragma mark Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.baseScrollView){
        [self baseScrollViewDidScroll];
    } else if (scrollView == self.headerScrollView) {
        [self headerScrollViewDidScroll];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.baseScrollView){
        [self baseScrollViewDidEndDecelerating];
    } else if (scrollView == self.headerScrollView) {
        [self headerScrollViewDidEndDecelerating];
    }
}

- (void)baseScrollViewDidScroll
{
    if (!self.baseScrollView.isDecelerating){
        
        //NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSInteger contentOffsetToChangeSong = 50;//[defaults integerForKey:@"contentOffsetToSwitchSong"];
        
        if (self.baseScrollView.contentOffset.x >= contentOffsetToChangeSong) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToNext;
        } else if (self.baseScrollView.contentOffset.x <= -contentOffsetToChangeSong ) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToPrevious;
        } else {
            self.ipodActionToPerformOnScrollViewDeceleration = None;
        }
    }
}

- (void)headerScrollViewDidScroll
{
    
}

- (void)baseScrollViewDidEndDecelerating
{
    switch (self.ipodActionToPerformOnScrollViewDeceleration) {
        case SkipToNext:
            
            if (self.ipod.playbackState == MPMusicPlaybackStatePlaying) {
                [self.ipod skipToNextItem];
            }
            
            break;
            
        case SkipToPrevious:
            
            if (self.ipod.playbackState == MPMusicPlaybackStatePlaying) {
                [self.ipod skipToPreviousItem];
            }
            
            break;
            
        default:
            break;
    }
    self.ipodActionToPerformOnScrollViewDeceleration = None;
}

- (void)headerScrollViewDidEndDecelerating
{
    CGFloat pageWidth = self.headerScrollView.frame.size.width;
    float fractionalPage = self.headerScrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    
    self.headerScrollViewPageControl.currentPage = page;
    [self.headerScrollViewPageControl updateCurrentPageDisplay];
    
    if (page == 0){
        self.headerScrollView.delaysContentTouches = NO;
    } else {
        self.headerScrollView.delaysContentTouches = YES;
    }
}

#pragma mark Setup

#pragma mark Base

- (void)setupBase
{
    [self setupBaseScrollView];
    [self setupBaseTapGestureRecognizer];
    [self setupBaseLongHoldGestureRecognizer];
    [self setupAlbumArtworkView];
    [self setupBaseScrollViewLabels];
}

- (void)setupBaseScrollView
{
    if (!self.baseScrollView){
        self.baseScrollView = [[UIScrollView alloc] init];
        self.baseScrollView.delegate = self;
        //self.baseScrollView.backgroundColor = [UIColor clearColor];
        self.baseScrollView.scrollEnabled = YES;
        self.baseScrollView.userInteractionEnabled = YES;
        self.baseScrollView.alwaysBounceHorizontal = YES;
        self.baseScrollView.showsHorizontalScrollIndicator = NO;
        self.baseScrollView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:self.baseScrollView];
    }
    
    self.baseScrollView.frame = CGRectMake(0, VIEW_HEADER_HEIGHT, self.view.frame.size.width, VIEW_HEIGHT);
    self.baseScrollView.contentSize = self.baseScrollView.frame.size;
}

- (void)setupBaseTapGestureRecognizer
{
    if (!self.tapGestureRecognizer){
        self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
        [self.baseScrollView addGestureRecognizer:self.tapGestureRecognizer];
    }
}

- (void)setupBaseLongHoldGestureRecognizer
{
    if (!self.longHoldGestureRecognizer){
        self.longHoldGestureRecognizer = [[UILongPressGestureRecognizer alloc]
                                          initWithTarget:self
                                          action:@selector(onLongHold:)];
        self.longHoldGestureRecognizer.minimumPressDuration = 1.0;
        [self.baseScrollView addGestureRecognizer:self.longHoldGestureRecognizer];
    }
}

- (void)setupAlbumArtworkView
{
    if (!self.albumArt){
        self.albumArt = [[UIImageView alloc] initWithImage:IMAGE_DISC];
        [self.baseScrollView addSubview:self.albumArt];
        self.albumArt.contentMode = UIViewContentModeScaleToFill;
    }
    
    [UIView setSize:self.albumArt newSize:CGSizeMake(ALBUM_ART_SIZE, ALBUM_ART_SIZE)];
    [UIView setOriginX:self.albumArt newOrigin:ALBUM_ART_PADDING];
    
    if (!self.albumIsOniCloud){
        self.albumIsOniCloud = [[UIImageView alloc] initWithImage:IMAGE_CLOUD];
        self.albumIsOniCloud.hidden = YES;
        [self.baseScrollView addSubview:self.albumIsOniCloud];
    }
    
    [UIView setSize:self.albumIsOniCloud
            newSize:CGSizeMake(ICLOUD_IMAGE_SIZE, ICLOUD_IMAGE_SIZE)];
    
    CGPoint icloudPoint = CGPointMake(self.albumArt.frame.size.width, self.albumArt.frame.size.height);
    [self.albumIsOniCloud setCenter:[self.baseScrollView convertPoint:icloudPoint fromView:self.albumArt]];
}

- (void)setupBaseScrollViewLabels
{
    //song title
    if (!self.songTitle){
        self.songTitle = [self createBaseScrollViewLabel];
        self.songTitle.text = @"";
    }
    
    [UIView setOrigin:self.songTitle newOrigin:CGPointMake(self.albumArt.frame.origin.x
                                                           + self.albumArt.frame.size.width
                                                           + ALBUM_ART_PADDING,
                                                           self.albumArt.frame.origin.y)];
    [UIView setSize:self.songTitle newSize:CGSizeMake(self.view.frame.size.width
                                                      - self.songTitle.frame.origin.x,
                                                      self.albumArt.frame.size.height / 3)];
    
    self.songTitle.text = self.songTitle.text;
    
    //song artist
    if (!self.songArtist){
        self.songArtist = [self createBaseScrollViewLabel];
        self.songArtist.text = @"";
    }
    
    [UIView setSize:self.songArtist newSize:self.songTitle.frame.size];
    [UIView setOrigin:self.songArtist newOrigin:CGPointMake(self.songTitle.frame.origin.x,
                                                            self.songTitle.frame.origin.y
                                                            + self.songTitle.frame.size.height)];
    
    self.songArtist.text = self.songArtist.text;
    
    //song album
    if (!self.songAlbum){
        self.songAlbum = [self createBaseScrollViewLabel];
        self.songAlbum.text = @"";
    }
    
    [UIView setSize:self.songAlbum newSize:self.songArtist.frame.size];
    [UIView setOrigin:self.songAlbum newOrigin:CGPointMake(self.songArtist.frame.origin.x,
                                                           self.songArtist.frame.origin.y
                                                           + self.songArtist.frame.size.height)];
    
    self.songAlbum.text = self.songAlbum.text;

}

- (MarqueeLabel *)createBaseScrollViewLabel
{
    MarqueeLabel *l = [[MarqueeLabel alloc] initWithFrame:CGRectZero rate:20 andFadeLength:40];
    l.marqueeType = MLContinuous;
    l.textColor = [UIColor whiteColor];
    [self.baseScrollView addSubview:l];
    
    return l;
}

#pragma mark Header

- (void)setupHeader
{
    [self setupHeaderScrollView];
    [self setupHeaderTimeline];
    [self setupHeaderButtonView];
}

#pragma mark Header Timeline

- (void)setupHeaderScrollView
{
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, VIEW_HEADER_HEIGHT);
    
    if (!self.headerScrollView){
        self.headerScrollView = [[UIScrollView alloc] init];
        self.headerScrollView.delegate = self;
        self.headerScrollView.pagingEnabled = YES;
        self.headerScrollView.delaysContentTouches = NO;
        self.headerScrollView.showsHorizontalScrollIndicator = NO;
        self.headerScrollView.showsVerticalScrollIndicator = NO;
        [self.view addSubview:self.headerScrollView];
    }
    
    self.headerScrollView.frame = rect;
    self.headerScrollView.contentSize = CGSizeMake(rect.size.width * 2, rect.size.height);
    
    if(!self.headerScrollViewPageControl){
        self.headerScrollViewPageControl = [[UIPageControl alloc] init];
        self.headerScrollViewPageControl.numberOfPages = 2;
        [self.view insertSubview:self.headerScrollViewPageControl belowSubview:self.headerScrollView];
    }
    
    self.headerScrollViewPageControl.frame = CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 20);
    
    [UIView setOriginY:self.headerScrollViewPageControl
             newOrigin:(self.headerScrollView.frame.origin.y +
                        self.headerScrollView.frame.size.height) -
     self.headerScrollViewPageControl.frame.size.height +
     HEADER_PAGE_DOT_INDICATOR_OFFSET];
}

- (void)setupHeaderTimeline
{
    if (!self.headerSongTimelineView){
        self.headerSongTimelineView = [[UIView alloc] init];
    }
    
    self.headerSongTimelineView.frame = self.headerScrollView.frame;
    [UIView setOrigin:self.headerSongTimelineView newOrigin:CGPointMake(VIEW_X_OFFSET, 0)];
    
    if (!self.songCurrentTime){
        self.songCurrentTime = [self createBasicLabel];
        [self.headerSongTimelineView addSubview:self.songCurrentTime];
        self.songCurrentTime.text = @"0:00";
        self.songCurrentTime.textAlignment = NSTextAlignmentCenter;
        self.songCurrentTime.adjustsFontSizeToFitWidth = YES;
    }
    
    [UIView setSize:self.songCurrentTime newSize:CGSizeMake(HEADER_SONG_TIME_LABEL_WIDTH,
                                                            25)];
    
    if (!self.songTotalTime){
        self.songTotalTime = [self createBasicLabel];
        self.songTotalTime.text = @"0:00";
        self.songTotalTime.textAlignment = NSTextAlignmentCenter;
        self.songTotalTime.adjustsFontSizeToFitWidth = YES;
        [self.headerSongTimelineView addSubview:self.songTotalTime];
    }
    
    [UIView setSize:self.songTotalTime newSize:CGSizeMake(HEADER_SONG_TIME_LABEL_WIDTH,
                                                          25)];
    [UIView setUpperRightOriginX:self.songTotalTime newOrigin:self.view.frame.size.width - VIEW_X_OFFSET];
    
    
    
    if (!self.timelineScrubber){
        self.timelineScrubber = [[UISliderCustom alloc] init];
        [self.timelineScrubber addTarget:self action:@selector(onTimelineValueChange:)
                        forControlEvents:UIControlEventValueChanged];
        [self.headerScrollView addSubview:self.headerSongTimelineView];
        self.timelineScrubber.minimumTrackTintColor = [UIColor whiteColor];
        self.timelineScrubber.maximumTrackTintColor = [UIColor grayColor];
        [self.headerSongTimelineView addSubview:self.timelineScrubber];
    }
    
    [UIView setSize:self.timelineScrubber newSize:CGSizeMake(self.headerSongTimelineView.frame.size.width -
                                                             (HEADER_SONG_TIME_LABEL_WIDTH * 2) -
                                                             (HEADER_TIMELINE_SCRUBBER_X_PADDING * 2),
                                                             25)];
    [UIView setOriginX:self.timelineScrubber
             newOrigin:HEADER_SONG_TIME_LABEL_WIDTH + HEADER_TIMELINE_SCRUBBER_X_PADDING];
    [UIView setCenterY:self.timelineScrubber newCenter:self.headerSongTimelineView.frame.size.height / 2];
    
    
    
    [UIView setCenterY:self.songTotalTime newCenter:self.timelineScrubber.center.y];
    [UIView setCenterY:self.songCurrentTime newCenter:self.timelineScrubber.center.y];
}

#pragma mark Header Button View

- (void)setupHeaderButtonView
{
    if (!self.headerButtonView){
        self.headerButtonView = [[UIView alloc] init];
        [self.headerScrollView addSubview:self.headerButtonView];
    }
    
    self.headerButtonView.frame = self.headerScrollView.frame;
    
    [UIView setOrigin:self.headerButtonView newOrigin:CGPointMake(self.headerScrollView.frame.origin.x +
                                                                        self.headerScrollView.frame.size.width,
                                                                        self.headerScrollView.frame.origin.y)];
    
    [self setupHeaderButtons];
}

- (void)setupHeaderButtons
{
    //[self setupShuffleButton];
    //[self setupRepeatButton];
    [self setupTwitterButton];
    [self setupFacebookButton];
    [self setupDonateButton];
}

/*- (void)setupShuffleButton
{
    if (!self.shuffleButton){
        self.shuffleButton = [self createHeaderButtonWithImage:IMAGE_SHUFFLE_ON];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 5);
    CGFloat center = (x * 0) + (x / 2);
    
    self.shuffleButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
    [self.shuffleButton addTarget:self action:@selector(shuffleButtonClicked)
                 forControlEvents:UIControlEventTouchUpInside];
    
    //[self updateShuffleButtonToCurrentState];
}

- (void)setupRepeatButton
{
    if (!self.repeatButton){
        self.repeatButton = [self createHeaderButtonWithImage:IMAGE_REPEAT_ALL];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 5);
    CGFloat center = (x * 1) + (x / 2);
    
    self.repeatButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
    [self.repeatButton addTarget:self action:@selector(repeateButtonClicked)
                forControlEvents:UIControlEventTouchUpInside];
    
    //[self updateRepeatButtonToCurrentState];
}
*/
- (void)setupTwitterButton
{
    if (!self.twitterButton){
        self.twitterButton = [self createHeaderButtonWithImage:IMAGE_TWITTER_ON];
        [self.twitterButton addTarget:self action:@selector(twitterButtonClicked)
                     forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 3);
    CGFloat center = (x * 0) + (x / 2);
    
    self.twitterButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
}

- (void)setupFacebookButton
{
    if (!self.facebookButton){
        self.facebookButton = [self createHeaderButtonWithImage:IMAGE_FACEBOOK_ON];
        [self.facebookButton addTarget:self action:@selector(facebookButtonClicked)
                      forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 3);
    CGFloat center = (x * 1) + (x / 2);
    
    self.facebookButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
}

- (void)setupDonateButton
{
    if (!self.donateButton){
        self.donateButton = [self createHeaderButtonWithImage:IMAGE_DONATE];
        [self.donateButton addTarget:self action:@selector(donateButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 3);
    CGFloat center = (x * 2) + (x / 2);
    
    self.donateButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
}

- (UIButton *)createHeaderButtonWithImage:(UIImage *)image
{
    if (!image){
        return nil;
    }
    
    //NSInteger buttonWidth = image.size.width;//(self.headerButtonView.frame.size.width / 5);
    
    UIButton *returnButton = [[UIButton alloc] init];
    [UIView setSize:returnButton newSize:CGSizeMake(image.size.width, image.size.height)];
    [returnButton setImage:image forState:UIControlStateNormal];
    [self.headerButtonView addSubview:returnButton];
    
    return returnButton;
}

#pragma mark Other

- (UILabel *)createBasicLabel
{
    UILabel *l = [[UILabel alloc] init];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor whiteColor];
    
    return l;
}

- (void)setupiPodListeners
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(oniPodItemChanged:)
                                                 name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(oniPodStateChanged:)
                                                 name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                               object:nil];
    
    [self.ipod beginGeneratingPlaybackNotifications];
}

- (void)cleanupiPodListeners
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:MPMusicPlayerControllerPlaybackStateDidChangeNotification
                                                  object:nil];
    
    [self.ipod endGeneratingPlaybackNotifications];
}

#pragma mark Cleanup

- (void)reset
{
    [self resetHeader];
}

- (void)resetHeader
{
    self.songCurrentTime.text = @"0:00";
    self.songTotalTime.text = @"0:00";
}

- (void)dealloc
{
    [self.baseScrollView removeGestureRecognizer:self.tapGestureRecognizer];
    [self stopUpdateSongPlaybackTimeTimer];
    [self.timelineScrubber removeTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
    
   /* [self.shuffleButton removeTarget:self action:@selector(shuffleButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.shuffleButton release];
    
    [self.repeatButton removeTarget:self action:@selector(repeateButtonClicked)
                   forControlEvents:UIControlEventTouchUpInside];
    [self.repeatButton release];*/
    
    [self.twitterButton removeTarget:self action:@selector(twitterButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.facebookButton removeTarget:self action:@selector(facebookButtonClicked)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.donateButton removeTarget:self action:@selector(donateButtonClicked)
                   forControlEvents:UIControlEventTouchUpInside];
    
    [self.background release];
    [self.baseScrollView release];
    [self.albumIsOniCloud release];
    [self.songTitle release];
    [self.songArtist release];
    [self.songAlbum release];
    
    [self.tapGestureRecognizer release];
    [self.longHoldGestureRecognizer release];
    
    [self.headerScrollView release];
    [self.headerScrollViewPageControl release];
    
    [self.headerSongTimelineView release];
    [self.songCurrentTime release];
    [self.songTotalTime release];
    [self.timelineScrubber release];
    [self.updateSongPlaybackTimeTimer release];
    
    [self.headerButtonView release];
    //[self.shuffleButton release];
    //[self.repeatButton release];
    [self.twitterButton release];
    [self.facebookButton release];
    [self.donateButton release];
    
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
