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

#import <Social/Social.h>

#import "SBMediaController.h"
#import "SBApplication.h"
#import "SBApplicationController.h"

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
#define IMAGE_SHUFFLE_ON [UIImage imageFromBundleWithName:@"white_shuffle.png"]
#define IMAGE_SHUFFLE_OFF [UIImage imageFromBundleWithName:@"grey_shuffle.png"]

#define IMAGE_REPEAT_ALL [UIImage imageFromBundleWithName:@"white_repeat.png"]
#define IMAGE_REPEAT_ONE [UIImage imageFromBundleWithName:@"white_repeat_one.png"]
#define IMAGE_REPEAT_OFF [UIImage imageFromBundleWithName:@"grey_repeat.png"]

#define IMAGE_TWITTER_ON [UIImage imageFromBundleWithName:@"white_twitter.png"]

#define IMAGE_FACEBOOK_ON [UIImage imageFromBundleWithName:@"white_facebook.png"]

#define IMAGE_DONATE [UIImage imageFromBundleWithName:@"white_donate.png"]

@interface NCMusicGesturesView(){
    MPMusicPlayerController* _ipod;
    SBMediaController *mediaController;
}

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
@property (strong, nonatomic) UIButton *shuffleButton;
@property (strong, nonatomic) UIButton *repeatButton;
@property (retain, nonatomic) UIButton *twitterButton;
@property (retain, nonatomic) UIButton *facebookButton;
@property (retain, nonatomic) UIButton *donateButton;

@end

@implementation NCMusicGesturesView

- (id)init
{
    self = [super init];
    if (self) {
        self.view.backgroundColor = [UIColor clearColor];
        self.view.clipsToBounds = YES;
        
        mediaController = [objc_getClass("SBMediaController") sharedInstance];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector:@selector(oniPodItemChanged)
                                                     name:@"SBMediaNowPlayingChangedNotification"
                                                   object:mediaController];
        
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
    self.background.frame = self.view.frame;
    [UIView setOrigin:self.background newOrigin:CGPointZero];
    
    [self setupBase];
    
    NSInteger currentPage = (self.headerScrollViewPageControl) ? self.headerScrollViewPageControl.currentPage : 0;
    
    [self setupHeader];
    
    self.headerScrollView.contentOffset = CGPointMake(self.headerScrollView.frame.size.width * (currentPage), 0);
    
    [self startUpdateSongPlaybackTimeTimer];
    
    [self updateShuffleButtonToCurrentState];
    [self updateRepeatButtonToCurrentState];
}

- (void)onViewDidDissappear
{
    [self stopUpdateSongPlaybackTimeTimer];
}


#pragma mark Gesture Recognizer

- (void)onTap:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded){
        [mediaController togglePlayPause];
        [self performPlayPauseAnimation];
    }
}

- (void)onLongHold:(UILongPressGestureRecognizer *)hold
{
    if (hold.state == UIGestureRecognizerStateBegan){
        
        SBApplication *currentApp = [mediaController nowPlayingApplication];
        
        if (currentApp){
            [[objc_getClass("SBUIController") sharedInstance] activateApplicationFromSwitcher:currentApp];
        } else {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"music://"]];
        }
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

- (void)oniPodItemChanged
{
    [self updateShuffleButtonToCurrentState];
    [self updateRepeatButtonToCurrentState];
    
    NSString *songTitle = [[mediaController _nowPlayingInfo] objectForKey:@"title"];
    NSString *songArtist = [[mediaController _nowPlayingInfo] objectForKey:@"artist"];
    NSString *songAlbum =[[mediaController _nowPlayingInfo] objectForKey:@"album"];
    
    self.songTitle.text = songTitle;
    self.songArtist.text = songArtist;
    self.songAlbum.text = songAlbum;

    self.albumIsOniCloud.hidden = YES;
    
    if ([mediaController trackIsBeingPlayedByMusicApp]){
        MPMusicPlayerController *ipod = [MPMusicPlayerController iPodMusicPlayer];
        
        if (ipod){
            MPMediaItem *currentItem = ipod.nowPlayingItem;
            
            if (currentItem){
                self.albumIsOniCloud.hidden = ![[currentItem valueForProperty:MPMediaItemPropertyIsCloudItem]
                                                boolValue];
            }
        }
    }
    
    NSData *imageData = [[mediaController _nowPlayingInfo] objectForKey:@"artworkData"];
    
    if (imageData){
        UIImage *art = [[UIImage alloc] initWithData:imageData];
        [self setAlbumArtToNewImage:art animated:YES halfCompletion:nil completion:nil];
        [art release];
    } else {
        [self setAlbumArtToNewImage:nil animated:YES halfCompletion:nil completion:nil];
    }
}

- (void)setAlbumArtToNewImage:(UIImage *)image
                     animated:(BOOL)animated
               halfCompletion:(void (^)())halfCompletion
                   completion:(void (^)())completion
{
    UIImage *newImage = (image) ? image : IMAGE_DISC;
    self.albumArt.image = newImage;
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
    NSInteger currentItemLength = [mediaController trackDuration];
    NSInteger newPlaybackTime = currentItemLength * slider.value;
    
    [mediaController setCurrentTrackTime:newPlaybackTime];
    
    double songTime = (NSInteger)[mediaController trackDuration];
    double songElapsedTime = (NSInteger)[mediaController trackElapsedTime];
    
    double songTimeLeft = songTime - songElapsedTime;
    
    self.songTotalTime.text = [StringFormatter
                               formattedStringForDurationHMS:(NSInteger)songTimeLeft];
    self.songCurrentTime.text = [StringFormatter
                                 formattedStringForDurationHMS:(NSInteger)songElapsedTime];
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
    
    if ([mediaController _nowPlayingInfo]){
        double songTime = (NSInteger)[mediaController trackDuration];
        double songElapsedTime = (NSInteger)[mediaController trackElapsedTime];
        
        double songTimeLeft = songTime - songElapsedTime;
        
        self.songTotalTime.text = [StringFormatter
                                   formattedStringForDurationHMS:(NSInteger)songTimeLeft];
        self.songCurrentTime.text = [StringFormatter
                                     formattedStringForDurationHMS:(NSInteger)songElapsedTime];
        
        float currentPlaybackPercentage = songElapsedTime / songTime;
        self.timelineScrubber.value = currentPlaybackPercentage;
    }
}

- (void)shuffleButtonClicked
{
    [mediaController toggleShuffle];
}

- (void)updateShuffleButtonToCurrentState
{
    switch ([mediaController shuffleMode]) {
        case 0:
            [self.shuffleButton setImage:IMAGE_SHUFFLE_OFF forState:UIControlStateNormal];
            break;
            
        case 2:
             [self.shuffleButton setImage:IMAGE_SHUFFLE_ON forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)repeateButtonClicked
{
    [mediaController toggleRepeat];
}

- (void)updateRepeatButtonToCurrentState
{
    switch ([mediaController repeatMode]) {
        case 0:
            [self.repeatButton setImage:IMAGE_REPEAT_OFF forState:UIControlStateNormal];
            break;
            
        case 1:
            [self.repeatButton setImage:IMAGE_REPEAT_ONE forState:UIControlStateNormal];
            break;
            
        case 2:
            [self.repeatButton setImage:IMAGE_REPEAT_ALL forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)twitterButtonClicked
{
    [self shareCurentSongWithServiceType:SLServiceTypeTwitter];
}

- (void)facebookButtonClicked
{
    [self shareCurentSongWithServiceType:SLServiceTypeFacebook];
}

- (void)shareCurentSongWithServiceType:(NSString *)serviceType
{
    if ([SLComposeViewController isAvailableForServiceType:serviceType])
    {
        if ([mediaController _nowPlayingInfo]){
            
            NSString *songTitle = [[mediaController _nowPlayingInfo] objectForKey:@"title"];
            NSString *songArtist = [[mediaController _nowPlayingInfo] objectForKey:@"artist"];
            
            UIImage *art;
            NSData *imageData = [[mediaController _nowPlayingInfo] objectForKey:@"artworkData"];
            
            if (imageData){
                art = [[UIImage alloc] initWithData:imageData];
            }
            
            SLComposeViewController *composeVC = [SLComposeViewController
                                                  composeViewControllerForServiceType:serviceType];
            
            NSMutableString *message = [NSMutableString stringWithFormat:@"%@%@",
                                        @"I'm listening to ", songTitle];
            
            if (songArtist){
                [message appendFormat:@"%@%@%@", @" by ", songArtist, @" #nowplaying"];
            }
            
            [composeVC setInitialText:message];
            
            if (art){
                [composeVC addImage:art];
                [art release];
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
        NSInteger contentOffsetToChangeSong = 40;//[defaults integerForKey:@"contentOffsetToSwitchSong"];
        
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
            
            [mediaController changeTrack:1];
            
            break;
            
        case SkipToPrevious:
            
            [mediaController changeTrack:-1];
            
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
    [self setupShuffleButton];
    [self setupRepeatButton];
    [self setupTwitterButton];
    [self setupFacebookButton];
    [self setupDonateButton];
}

- (void)setupShuffleButton
{
    if (!self.shuffleButton){
        self.shuffleButton = [self createHeaderButtonWithImage:IMAGE_SHUFFLE_ON];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 5);
    CGFloat center = (x * 0) + (x / 2);
    
    self.shuffleButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
    [self.shuffleButton addTarget:self action:@selector(shuffleButtonClicked)
                 forControlEvents:UIControlEventTouchUpInside];
    
    [self updateShuffleButtonToCurrentState];
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
    
    [self updateRepeatButtonToCurrentState];
}

- (void)setupTwitterButton
{
    if (!self.twitterButton){
        self.twitterButton = [self createHeaderButtonWithImage:IMAGE_TWITTER_ON];
        [self.twitterButton addTarget:self action:@selector(twitterButtonClicked)
                     forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 5);
    CGFloat center = (x * 2) + (x / 2);
    
    self.twitterButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
}

- (void)setupFacebookButton
{
    if (!self.facebookButton){
        self.facebookButton = [self createHeaderButtonWithImage:IMAGE_FACEBOOK_ON];
        [self.facebookButton addTarget:self action:@selector(facebookButtonClicked)
                      forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 5);
    CGFloat center = (x * 3) + (x / 2);
    
    self.facebookButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
}

- (void)setupDonateButton
{
    if (!self.donateButton){
        self.donateButton = [self createHeaderButtonWithImage:IMAGE_DONATE];
        [self.donateButton addTarget:self action:@selector(donateButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    }
    
    CGFloat x = (self.headerScrollView.frame.size.width / 5);
    CGFloat center = (x * 4) + (x / 2);
    
    self.donateButton.center = CGPointMake(center, self.headerScrollView.frame.size.height / 2);
}

- (UIButton *)createHeaderButtonWithImage:(UIImage *)image
{
    if (!image){
        return nil;
    }
    
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
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"SBMediaNowPlayingChangedNotification"
                                                  object:mediaController];
    
    [self.baseScrollView removeGestureRecognizer:self.tapGestureRecognizer];
    [self stopUpdateSongPlaybackTimeTimer];
    [self.timelineScrubber removeTarget:self
                                 action:@selector(onTimelineValueChange:)
                       forControlEvents:UIControlEventValueChanged];
    
    [self.shuffleButton removeTarget:self action:@selector(shuffleButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.shuffleButton release];
    
    [self.repeatButton removeTarget:self action:@selector(repeateButtonClicked)
                   forControlEvents:UIControlEventTouchUpInside];
    [self.repeatButton release];
    
    [self.twitterButton removeTarget:self action:@selector(twitterButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.facebookButton removeTarget:self action:@selector(facebookButtonClicked)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.donateButton removeTarget:self action:@selector(donateButtonClicked)
                   forControlEvents:UIControlEventTouchUpInside];
    
    
    [self.background release];
    self.background = nil;
    [self.baseScrollView release];
    self.baseScrollView = nil;
    
    [self.albumArt release];
    self.albumArt = nil;
    [self.albumIsOniCloud release];
    self.albumIsOniCloud = nil;
    [self.songTitle release];
    self.songTitle = nil;
    [self.songArtist release];
    self.songArtist = nil;
    [self.songAlbum release];
    self.songAlbum = nil;
    
    [self.tapGestureRecognizer release];
    self.tapGestureRecognizer = nil;
    [self.longHoldGestureRecognizer release];
    self.longHoldGestureRecognizer = nil;
    
    [self.headerScrollView release];
    self.headerScrollView = nil;
    [self.headerScrollViewPageControl release];
    self.headerScrollViewPageControl = nil;
    
    [self.headerSongTimelineView release];
    self.headerSongTimelineView = nil;
    [self.songCurrentTime release];
    self.songCurrentTime = nil;
    [self.songTotalTime release];
    self.songTotalTime = nil;
    [self.timelineScrubber release];
    self.timelineScrubber = nil;
    [self.updateSongPlaybackTimeTimer release];
    self.updateSongPlaybackTimeTimer = nil;
    
    [self.headerButtonView release];
    self.headerButtonView = nil;
    [self.twitterButton release];
    self.twitterButton = nil;
    [self.facebookButton release];
    self.facebookButton = nil;
    [self.donateButton release];
    self.donateButton = nil;
    
    [super dealloc];
}

@end
