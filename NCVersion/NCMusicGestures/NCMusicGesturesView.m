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
#import "NCMusicGesturesHeader.h"
#import "StringFormatter.h"
#import "UIImage+UIImageExtensions.h"

#define BACKGROUND_CAP_VALUE 5
#define CONTENT_OFFSET_NEEDED_TO_SKIP_SONG 50

#define VIEW_X_OFFSET 2
#define TOTAL_VIEW_HEIGHT (VIEW_HEADER_HEIGHT + VIEW_HEIGHT)

#define ALBUM_ART_ANIM_TIME 0.5
#define ALBUM_ART_PADDING 10
#define ALBUM_ART_SIZE 85
#define ICLOUD_IMAGE_SIZE 20

#define IMAGE_BACKGROUND [UIImage imageFromBundleWithName:@"WeeAppBackground.png"]
#define IMAGE_DISC [UIImage imageFromBundleWithName:@"cddisc.png"]
#define IMAGE_CLOUD [UIImage imageFromBundleWithName:@"white_cloud.png"]

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

@property (readwrite, nonatomic) IPOD_ACTION_TO_PERFORM ipodActionToPerformOnScrollViewDeceleration;

@property (strong, nonatomic) UIImageView *background;
@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) UIImageView *albumArt;
@property (strong, nonatomic) UIImageView *albumIsOniCloud;
@property (strong, nonatomic) UILabel *songTitle;
@property (strong, nonatomic) UILabel *songArtist;
@property (strong, nonatomic) UILabel *songAlbum;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (strong, nonatomic) NCMusicGesturesHeader *header;

@end

@implementation NCMusicGesturesView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self){
        UIImage *bg = [IMAGE_BACKGROUND stretchableImageWithLeftCapWidth:BACKGROUND_CAP_VALUE
                                                            topCapHeight:BACKGROUND_CAP_VALUE];
		self.background = [[UIImageView alloc] initWithImage:bg];
		self.background.frame = frame;
		[self addSubview:self.background];
        [UIView setOrigin:self.background newOrigin:CGPointZero];
        
        self.ipodActionToPerformOnScrollViewDeceleration = None;
        
        [self setupScrollView];
        [self setupAlbumArtworkView];
        [self setupScrollViewLabels];
        [self setupTapGestureRecognizer];
        
        [self setupiPodListeners];
        
        [self setupHeader];
        return self;
        
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
        self.scrollView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished){
        [UIView animateWithDuration:0.1 animations:^{
            self.scrollView.transform = CGAffineTransformMakeScale(1.0, 1.0);
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
        [self.header setInfoFromMPMediaItem:item animated:animated];
        
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
        
        [self.header reset];
        
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

#pragma mark Scroll View

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!self.scrollView.isDecelerating){
        
        if (self.scrollView.contentOffset.x >= CONTENT_OFFSET_NEEDED_TO_SKIP_SONG) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToNext;
        } else if (self.scrollView.contentOffset.x <= -CONTENT_OFFSET_NEEDED_TO_SKIP_SONG ) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToPrevious;
        } else {
            self.ipodActionToPerformOnScrollViewDeceleration = None;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
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

#pragma mark Setup

- (void)setupScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.scrollEnabled = YES;
    self.scrollView.userInteractionEnabled = YES;
    self.scrollView.alwaysBounceHorizontal = YES;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    self.scrollView.frame = CGRectMake(0, VIEW_HEADER_HEIGHT, self.frame.size.width, VIEW_HEIGHT);
    self.scrollView.contentSize = self.scrollView.frame.size;
}

- (void)setupAlbumArtworkView
{
    self.albumArt = [[UIImageView alloc] initWithImage:IMAGE_DISC];
    
    [self.scrollView addSubview:self.albumArt];
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

- (void)setupScrollViewLabels
{
    //song title
    self.songTitle = [self createScrollViewLabel];
    [UIView setOrigin:self.songTitle newOrigin:CGPointMake(self.albumArt.frame.origin.x
                                                           + self.albumArt.frame.size.width
                                                           + ALBUM_ART_PADDING,
                                                           self.albumArt.frame.origin.y)];
    [UIView setSize:self.songTitle newSize:CGSizeMake(self.frame.size.width
                                                      - self.songTitle.frame.origin.x,
                                                      self.albumArt.frame.size.height / 3)];
    
    //song artist
    self.songArtist = [self createScrollViewLabel];
    [UIView setSize:self.songArtist newSize:self.songTitle.frame.size];
    [UIView setOrigin:self.songArtist newOrigin:CGPointMake(self.songTitle.frame.origin.x,
                                                            self.songTitle.frame.origin.y
                                                            + self.songTitle.frame.size.height)];
    
    //song album
    self.songAlbum = [self createScrollViewLabel];
    [UIView setSize:self.songAlbum newSize:self.songArtist.frame.size];
    [UIView setOrigin:self.songAlbum newOrigin:CGPointMake(self.songArtist.frame.origin.x,
                                                           self.songArtist.frame.origin.y
                                                           + self.songArtist.frame.size.height)];

}

- (UILabel *)createBasicLabel
{
    UILabel *l = [[UILabel alloc] init];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor whiteColor];
    
    return l;
}

- (UILabel *)createScrollViewLabel
{
    UILabel *l = [self createBasicLabel];
    [self.scrollView addSubview:l];
    
    return l;
}

- (void)setupTapGestureRecognizer
{
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTap:)];
    [self.scrollView addGestureRecognizer:self.tapGestureRecognizer];
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

- (void)setupHeader
{
    CGRect rect = CGRectMake(0, 0, self.frame.size.width, VIEW_HEADER_HEIGHT);
    self.header = [[NCMusicGesturesHeader alloc] initWithFrame:rect];
    [self addSubview:self.header];
}

#pragma mark Cleanup

- (void)dealloc
{
    [[NCMusicGesturesView ipod] endGeneratingPlaybackNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    
    [self.background release];
    [self.scrollView removeGestureRecognizer:self.tapGestureRecognizer];
    [self.tapGestureRecognizer release];
    
    [self.albumArt release];
    [self.albumIsOniCloud release];
    [self.songTitle release];
    [self.songArtist release];
    [self.songAlbum release];
    
    [self.scrollView release];
    
    [self.header release];
    
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
