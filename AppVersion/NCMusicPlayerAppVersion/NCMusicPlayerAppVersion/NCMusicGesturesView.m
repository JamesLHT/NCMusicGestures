//
//  NCMusicGesturesView.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "NCMusicGesturesView.h"
#import "UIView+UIViewExtensions.h"
#import <MediaPlayer/MediaPlayer.h>
#import <Social/Social.h>
#import "NCMusicGesturesHeader.h"
#import "StringFormatter.h"
#import "UISliderCustom.h"

#define BACKGROUND_CAP_VALUE 5
#define CONTENT_OFFSET_NEEDED_TO_SKIP_SONG 50

#define VIEW_X_OFFSET 2
#define TOTAL_VIEW_HEIGHT (VIEW_HEADER_HEIGHT + VIEW_HEIGHT)

#define ALBUM_ART_ANIM_TIME 0.5
#define ALBUM_ART_PADDING 10
#define ALBUM_ART_SIZE 85
#define ICLOUD_IMAGE_SIZE 20

#define IMAGE_DISC [UIImage imageNamed:@"cddisc"]
#define IMAGE_CLOUD [UIImage imageNamed:@"white_cloud"]

//header
//header timeline view
#define HEADER_SONG_TIME_LABEL_WIDTH 60
#define HEADER_TIMELINE_SCRUBBER_X_PADDING 5
#define HEADER_PAGE_DOT_INDICATOR_OFFSET 6

//header button view
#define IMAGE_SHUFFLE_ON [UIImage imageNamed:@"white_shuffle"]
#define IMAGE_SHUFFLE_OFF [UIImage imageNamed:@"grey_shuffle"]

#define IMAGE_REPEAT_ALL [UIImage imageNamed:@"white_repeat"]
#define IMAGE_REPEAT_ONE [UIImage imageNamed:@"white_repeat_one"]
#define IMAGE_REPEAT_OFF [UIImage imageNamed:@"grey_repeat"]

#define IMAGE_TWITTER_OFF [UIImage imageNamed:@"grey_twitter"]
#define IMAGE_TWITTER_ON [UIImage imageNamed:@"white_twitter"]

#define IMAGE_FACEBOOK_OFF [UIImage imageNamed:@"grey_facebook"]
#define IMAGE_FACEBOOK_ON [UIImage imageNamed:@"white_facebook"]

#define IMAGE_DONATE [UIImage imageNamed:@"white_donate"]

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

@property (strong, nonatomic) UIImageView *background;
@property (strong, nonatomic) UIScrollView *baseScrollView;

@property (strong, nonatomic) UIImageView *albumArt;
@property (strong, nonatomic) UIImageView *albumIsOniCloud;
@property (strong, nonatomic) UILabel *songTitle;
@property (strong, nonatomic) UILabel *songArtist;
@property (strong, nonatomic) UILabel *songAlbum;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

//header
@property (strong, nonatomic) UIScrollView *headerScrollView;
@property (strong, nonatomic) UIPageControl *headerScrollViewPageControl;

@property (strong, nonatomic) UIView *headerSongTimelineView;
@property (strong, nonatomic) UILabel *songCurrentTime;
@property (strong, nonatomic) UILabel *songTotalTime;
@property (strong, nonatomic) UISliderCustom *timelineScrubber;
@property (strong, nonatomic) NSTimer *updateSongPlaybackTimeTimer;

@property (strong, nonatomic) UIView *headerButtonView;
@property (strong, nonatomic) UIButton *shuffleButton;
@property (strong, nonatomic) UIButton *repeatButton;
@property (strong, nonatomic) UIButton *twitterButton;
@property (strong, nonatomic) UIButton *facebookButton;
@property (strong, nonatomic) UIButton *donateButton;

@end

@implementation NCMusicGesturesView

- (id)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(VIEW_X_OFFSET, 0, VIEW_WIDTH_PORTRAIT, TOTAL_VIEW_HEIGHT);
        
        
        UIImage *bg = [[UIImage imageNamed:@"WeeAppBackground"]
                       stretchableImageWithLeftCapWidth:BACKGROUND_CAP_VALUE topCapHeight:BACKGROUND_CAP_VALUE];
		self.background = [[UIImageView alloc] initWithImage:bg];
		self.background.frame = CGRectMake(0, 0, VIEW_WIDTH_PORTRAIT, TOTAL_VIEW_HEIGHT);
		[self addSubview:self.background];
        
        self.ipodActionToPerformOnScrollViewDeceleration = None;
        
        //base
        [self setupBase];
        //header
        [self setupHeader];
        
        //other
        
        [self setupiPodListeners];
        
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationChange)
                                                     name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)onDeviceOrientationChange
{
    //[UIView setSizeX:self newSize:VIEW_WIDTH_PORTRAIT];
    return;
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    if (UIDeviceOrientationIsPortrait(orientation)){
        [UIView setSizeX:self.background newSize:self.window.frame.size.width];
    } else if (UIDeviceOrientationIsLandscape(orientation)){
        [UIView setSizeX:self.background newSize:self.window.frame.size.height];
    }
}

#pragma mark Gesture Recognizer

- (void)onTap:(UITapGestureRecognizer *)tap
{
    if (tap.state == UIGestureRecognizerStateEnded){
        if ([NCMusicGesturesView ipod].playbackState == MPMusicPlaybackStatePaused ||
            [NCMusicGesturesView ipod].playbackState == MPMusicPlaybackStateStopped){
            [[NCMusicGesturesView ipod] play];
            [self performPlayPauseAnimation];
        } else if ([NCMusicGesturesView ipod].playbackState == MPMusicPlaybackStatePlaying){
            [[NCMusicGesturesView ipod] pause];
            [self performPlayPauseAnimation];
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

+ (MPMusicPlayerController *)ipod
{
    return [MPMusicPlayerController iPodMusicPlayer];
}

- (void)oniPodItemChanged:(NSNotification *)notification
{
    self.albumIsOniCloud.hidden = YES;
    
    MPMusicPlayerController *mp = notification.object;
    MPMediaItem *item = mp.nowPlayingItem;
    
    if (!item){
        MPMediaQuery *everything = [[MPMediaQuery alloc] init];
        [[NCMusicGesturesView ipod] setQueueWithQuery:everything];
    }
    
    [self setInfoFromMPMediaItem:item animated:YES];
}

- (void)oniPodStateChanged:(NSNotification *)notification
{
    
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
        
        [UIView animateWithDuration:ALBUM_ART_ANIM_TIME / 2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.albumArt.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }completion:^(BOOL finished){
            
            if (halfCompletion){
                halfCompletion();
            }
            
            [UIView animateWithDuration:ALBUM_ART_ANIM_TIME / 2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
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
                        } completion:nil];
    } else {
        self.albumArt.image = newAlbumArtImage;
    }
}

#pragma mark Header

- (void)onTimelineValueChange:(UISlider *)slider
{
    NSInteger currentItemLength = [[[NCMusicGesturesView ipod].nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    NSInteger newPlaybackTime = currentItemLength * slider.value;
    
    if (newPlaybackTime != [NCMusicGesturesView ipod].currentPlaybackTime){
        [NCMusicGesturesView ipod].currentPlaybackTime = newPlaybackTime;
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
    
    if ([NCMusicGesturesView ipod].currentPlaybackTime <= 0){
        self.songCurrentTime.text = @"0:00";
    } else {
        self.songCurrentTime.text = [StringFormatter formattedStringForDurationHMS:[NCMusicGesturesView ipod].currentPlaybackTime];
    }
    
    NSInteger currentItemLength = [[[NCMusicGesturesView ipod].nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    float currentPlaybackPercentage = [NCMusicGesturesView ipod].currentPlaybackTime / currentItemLength;
    self.timelineScrubber.value = currentPlaybackPercentage;
}

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
        MPMediaItem *item = [NCMusicGesturesView ipod].nowPlayingItem;
        
        if (item){
            NSString *songTitle = [item valueForProperty:MPMediaItemPropertyTitle];
            NSString *songArtist = [item valueForProperty:MPMediaItemPropertyArtist];
            
            MPMediaItemArtwork *itemArtwork = [item valueForProperty:MPMediaItemPropertyArtwork];
            UIImage *albumArtImage = [itemArtwork imageWithSize:itemArtwork.bounds.size];
            
            SLComposeViewController *composeVC = [SLComposeViewController
                                                              composeViewControllerForServiceType:serviceType];
            UIViewController *shareVC = [[UIViewController alloc] init];
            shareVC.view = self;
            
            [composeVC setInitialText:[NSString stringWithFormat:@"%@%@%@%@",
                                                   @"I am listening to ", songTitle, @" by ", songArtist]];
            if (albumArtImage){
                [composeVC addImage:albumArtImage];
            }
            
            composeVC.completionHandler = ^(SLComposeViewControllerResult result){
                [shareVC dismissViewControllerAnimated:YES completion:^{
                    
                }];
            };
            
            [shareVC presentViewController:composeVC animated:YES completion:nil];
            
            [shareVC release];
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
        
        if (self.baseScrollView.contentOffset.x >= CONTENT_OFFSET_NEEDED_TO_SKIP_SONG) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToNext;
        } else if (self.baseScrollView.contentOffset.x <= -CONTENT_OFFSET_NEEDED_TO_SKIP_SONG ) { //in skip position
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
    if ([NCMusicGesturesView ipod].playbackState == MPMusicPlaybackStatePlaying ||
        [NCMusicGesturesView ipod].playbackState == MPMusicPlaybackStatePaused){
        switch (self.ipodActionToPerformOnScrollViewDeceleration) {
            case SkipToNext:
                
                [[NCMusicGesturesView ipod] skipToNextItem];
                
                break;
                
            case SkipToPrevious:
                
                [[NCMusicGesturesView ipod] skipToPreviousItem];
                
                break;
                
            default:
                break;
        }
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
    [self setupAlbumArtworkView];
    [self setupBaseScrollViewLabels];
}

- (void)setupBaseScrollView
{
    self.baseScrollView = [[UIScrollView alloc] init];
    self.baseScrollView.delegate = self;
    self.baseScrollView.backgroundColor = [UIColor clearColor];
    self.baseScrollView.scrollEnabled = YES;
    self.baseScrollView.userInteractionEnabled = YES;
    self.baseScrollView.alwaysBounceHorizontal = YES;
    self.baseScrollView.showsHorizontalScrollIndicator = NO;
    self.baseScrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.baseScrollView];
    self.baseScrollView.frame = CGRectMake(0, VIEW_HEADER_HEIGHT, self.frame.size.width, VIEW_HEIGHT);
    self.baseScrollView.contentSize = self.baseScrollView.frame.size;
}

- (void)setupBaseTapGestureRecognizer
{
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [self.baseScrollView addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)setupAlbumArtworkView
{
    self.albumArt = [[UIImageView alloc] initWithImage:IMAGE_DISC];
    
    [self.baseScrollView addSubview:self.albumArt];
    self.albumArt.contentMode = UIViewContentModeScaleToFill;
    [UIView setSize:self.albumArt newSize:CGSizeMake(ALBUM_ART_SIZE, ALBUM_ART_SIZE)];
    [UIView setOriginX:self.albumArt newOrigin:ALBUM_ART_PADDING];
    
    self.albumIsOniCloud = [[UIImageView alloc] initWithImage:IMAGE_CLOUD];
    [UIView setSize:self.albumIsOniCloud
            newSize:CGSizeMake(ICLOUD_IMAGE_SIZE, ICLOUD_IMAGE_SIZE)];
    self.albumIsOniCloud.hidden = YES;
    [self.albumArt addSubview:self.albumIsOniCloud];
    //[UIView setUpperRightOriginX:self.albumIsOniCloud newOrigin:self.albumArt.frame.size.width];
    //[UIView setOriginY:self.albumIsOniCloud
         //    newOrigin:self.albumArt.frame.size.height - self.albumIsOniCloud.frame.size.height];
    
    [self.albumIsOniCloud setCenter:CGPointMake(self.albumArt.frame.size.width, self.albumArt.frame.size.height)];
}

- (void)setupBaseScrollViewLabels
{
    //song title
    self.songTitle = [self createBaseScrollViewLabel];
    [UIView setOrigin:self.songTitle newOrigin:CGPointMake(self.albumArt.frame.origin.x
                                                           + self.albumArt.frame.size.width
                                                           + ALBUM_ART_PADDING,
                                                           self.albumArt.frame.origin.y)];
    [UIView setSize:self.songTitle newSize:CGSizeMake(self.frame.size.width
                                                      - self.songTitle.frame.origin.x,
                                                      self.albumArt.frame.size.height / 3)];
    
    //song artist
    self.songArtist = [self createBaseScrollViewLabel];
    [UIView setSize:self.songArtist newSize:self.songTitle.frame.size];
    [UIView setOrigin:self.songArtist newOrigin:CGPointMake(self.songTitle.frame.origin.x,
                                                            self.songTitle.frame.origin.y
                                                            + self.songTitle.frame.size.height)];
    
    //song album
    self.songAlbum = [self createBaseScrollViewLabel];
    [UIView setSize:self.songAlbum newSize:self.songArtist.frame.size];
    [UIView setOrigin:self.songAlbum newOrigin:CGPointMake(self.songArtist.frame.origin.x,
                                                           self.songArtist.frame.origin.y
                                                           + self.songArtist.frame.size.height)];

}

- (UILabel *)createBaseScrollViewLabel
{
    UILabel *l = [self createBasicLabel];
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
    CGRect rect = CGRectMake(0, 0, VIEW_WIDTH_PORTRAIT, VIEW_HEADER_HEIGHT);
    
    self.headerScrollView = [[UIScrollView alloc] initWithFrame:rect];
    self.headerScrollView.delegate = self;
    self.headerScrollView.pagingEnabled = YES;
    self.headerScrollView.delaysContentTouches = NO;
    self.headerScrollView.contentSize = CGSizeMake(rect.size.width * 2, rect.size.height);
    self.headerScrollView.showsHorizontalScrollIndicator = NO;
    self.headerScrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.headerScrollView];
    
    self.headerScrollViewPageControl = [[UIPageControl alloc] initWithFrame:
                                        CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 20)];
    [UIView setOriginY:self.headerScrollViewPageControl
             newOrigin:(self.headerScrollView.frame.origin.y +
                        self.headerScrollView.frame.size.height) -
     self.headerScrollViewPageControl.frame.size.height +
     HEADER_PAGE_DOT_INDICATOR_OFFSET];
    
    self.headerScrollViewPageControl.numberOfPages = 2;
    [self insertSubview:self.headerScrollViewPageControl belowSubview:self.headerScrollView];
    
    //CGRect rectTwo = CGRectMake(0, 0, VIEW_WIDTH_PORTRAIT, VIEW_HEADER_HEIGHT - 15);
    
    //self.headerPageOne = [[NCMusicGesturesHeaderPageOne alloc] initWithFrame:rectTwo];
    //[self.scrollView addSubview:self.headerPageOne];
    
    //self.headerPageTwo = [[NCMusicGesturesHeaderPageTwo alloc] initWithFrame:
    //   CGRectMake(rectTwo.origin.x + rectTwo.size.width, rectTwo.origin.y, rectTwo.size.width, rectTwo.size.height)];
    //[self.scrollView addSubview:self.headerPageTwo];
}

- (void)setupHeaderTimeline
{
    self.headerSongTimelineView = [[UIView alloc] initWithFrame:self.headerScrollView.frame];
    [UIView setOrigin:self.headerSongTimelineView newOrigin:CGPointZero];
    
    self.songCurrentTime = [self createBasicLabel];
    self.songCurrentTime.textAlignment = NSTextAlignmentCenter;
    self.songCurrentTime.adjustsFontSizeToFitWidth = YES;
    [self.headerSongTimelineView addSubview:self.songCurrentTime];
    [UIView setSize:self.songCurrentTime newSize:CGSizeMake(HEADER_SONG_TIME_LABEL_WIDTH,
                                                            self.headerScrollView.frame.size.height)];
    self.songCurrentTime.text = @"0:00";
    
    self.songTotalTime = [self createBasicLabel];
    self.songTotalTime.textAlignment = NSTextAlignmentCenter;
    self.songTotalTime.adjustsFontSizeToFitWidth = YES;
    [self.headerSongTimelineView addSubview:self.songTotalTime];
    [UIView setSize:self.songTotalTime newSize:CGSizeMake(HEADER_SONG_TIME_LABEL_WIDTH,
                                                          self.headerScrollView.frame.size.height)];
    [UIView setUpperRightOriginX:self.songTotalTime newOrigin:self.frame.size.width];
    self.songTotalTime.text = @"0:00";
    
    self.timelineScrubber = [[UISliderCustom alloc] init];
    self.timelineScrubber.minimumTrackTintColor = [UIColor whiteColor];
    self.timelineScrubber.maximumTrackTintColor = [UIColor grayColor];
    [self.headerSongTimelineView addSubview:self.timelineScrubber];
    [UIView setSize:self.timelineScrubber newSize:CGSizeMake(self.headerSongTimelineView.frame.size.width -
                                                             (HEADER_SONG_TIME_LABEL_WIDTH * 2) -
                                                             (HEADER_TIMELINE_SCRUBBER_X_PADDING * 2),
                                                             25)];
    [UIView setOriginX:self.timelineScrubber newOrigin:HEADER_SONG_TIME_LABEL_WIDTH + HEADER_TIMELINE_SCRUBBER_X_PADDING];
    [UIView setCenterY:self.timelineScrubber newCenter:self.headerSongTimelineView.frame.size.height / 2];
    [self.timelineScrubber addTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
    
    [self.headerScrollView addSubview:self.headerSongTimelineView];
}

#pragma mark Header Button View

- (void)setupHeaderButtonView
{
    self.headerButtonView = [[UIView alloc] initWithFrame:self.headerScrollView.frame];
    [UIView setOrigin:self.headerButtonView newOrigin:CGPointMake(self.headerScrollView.frame.origin.x +
                                                                        self.headerScrollView.frame.size.width,
                                                                        self.headerScrollView.frame.origin.y)];
    [self.headerScrollView addSubview:self.headerButtonView];
    
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
    self.shuffleButton = [self createHeaderButtonWithImage:IMAGE_SHUFFLE_ON];
    [UIView setOrigin:self.shuffleButton newOrigin:CGPointMake(0, 0)];
    [self.shuffleButton addTarget:self action:@selector(shuffleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupRepeatButton
{
    self.repeatButton = [self createHeaderButtonWithImage:IMAGE_REPEAT_ALL];
    [UIView setOrigin:self.repeatButton newOrigin:CGPointMake(self.shuffleButton.frame.origin.x +
                                                              self.shuffleButton.frame.size.width, 0)];
    [self.repeatButton addTarget:self action:@selector(repeateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTwitterButton
{
    self.twitterButton = [self createHeaderButtonWithImage:IMAGE_TWITTER_ON];
    [UIView setOrigin:self.twitterButton newOrigin:CGPointMake(self.repeatButton.frame.origin.x +
                                                               self.repeatButton.frame.size.width, 0)];
    [self.twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupFacebookButton
{
    self.facebookButton = [self createHeaderButtonWithImage:IMAGE_FACEBOOK_ON];
    [UIView setOrigin:self.facebookButton newOrigin:CGPointMake(self.twitterButton.frame.origin.x +
                                                                self.twitterButton.frame.size.width, 0)];
    [self.facebookButton addTarget:self action:@selector(facebookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupDonateButton
{
    self.donateButton = [self createHeaderButtonWithImage:IMAGE_DONATE];
    [UIView setOrigin:self.donateButton newOrigin:CGPointMake(self.facebookButton.frame.origin.x +
                                                              self.facebookButton.frame.size.width, 0)];
    [self.donateButton addTarget:self action:@selector(donateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *)createHeaderButtonWithImage:(UIImage *)image
{
    if (!image){
        return nil;
    }
    
    NSInteger buttonWidth = (self.headerButtonView.frame.size.width / 5);
    
    UIButton *returnButton = [[UIButton alloc] init];
    [UIView setSize:returnButton newSize:CGSizeMake(buttonWidth, self.headerButtonView.frame.size.height)];
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
    
    [[NCMusicGesturesView ipod] beginGeneratingPlaybackNotifications];
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
    //base
    
    [self.background release];
    [self.baseScrollView removeGestureRecognizer:self.tapGestureRecognizer];
    [self.tapGestureRecognizer release];
    
    [self.albumArt release];
    [self.albumIsOniCloud release];
    [self.songTitle release];
    [self.songArtist release];
    [self.songAlbum release];
    
    [self.baseScrollView release];
    
    //header
    //header timeline
    [self.headerSongTimelineView release];
    [self.headerScrollView release];
    [self.headerScrollViewPageControl release];
    
    [self stopUpdateSongPlaybackTimeTimer];
    
    [self.songCurrentTime release];
    [self.songTotalTime release];
    [self.timelineScrubber removeTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.timelineScrubber dealloc];
    
    //header button view
    [self.headerButtonView release];
    [self.shuffleButton removeTarget:self action:@selector(shuffleButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.shuffleButton release];
    
    [self.repeatButton removeTarget:self action:@selector(repeateButtonClicked)
                   forControlEvents:UIControlEventTouchUpInside];
    [self.repeatButton release];
    
    [self.twitterButton removeTarget:self action:@selector(twitterButtonClicked)
                    forControlEvents:UIControlEventTouchUpInside];
    [self.twitterButton release];
    
    [self.facebookButton removeTarget:self action:@selector(facebookButtonClicked)
                     forControlEvents:UIControlEventTouchUpInside];
    [self.facebookButton release];
    
    [self.donateButton removeTarget:self action:@selector(donateButtonClicked)
                   forControlEvents:UIControlEventTouchUpInside];
    [self.donateButton release];
    
    //other
    
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
