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

#define BACKGROUND_CAP_VALUE 5

#define VIEW_X_OFFSET 2
#define TOTAL_VIEW_HEIGHT (VIEW_HEADER_HEIGHT + VIEW_HEIGHT)

#define ALBUM_ART_ANIM_TIME 0.5
#define ALBUM_ART_PADDING 10
#define ALBUM_ART_SIZE 85

#define DEFAULT_ARTWORK_IMAGE [UIImage imageNamed:@"blankalbumart"]

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

@property (strong, nonatomic) UIScrollView *scrollView;

@property (strong, nonatomic) UIImageView *albumArt;
@property (strong, nonatomic) UILabel *songTitle;
@property (strong, nonatomic) UILabel *songArtist;
@property (strong, nonatomic) UILabel *songAlbum;

@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (strong, nonatomic) NCMusicGesturesHeader *header;

//@property (strong, nonatomic) UIButton

@end

@implementation NCMusicGesturesView

- (id)init
{
    self = [super init];
    if (self) {
        self.frame = CGRectMake(VIEW_X_OFFSET, 0, VIEW_WIDTH, TOTAL_VIEW_HEIGHT);
        
        
        UIImage *bg = [[UIImage imageNamed:@"WeeAppBackground"]
                       stretchableImageWithLeftCapWidth:BACKGROUND_CAP_VALUE topCapHeight:BACKGROUND_CAP_VALUE];
		UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectMake(0, 0, VIEW_WIDTH, TOTAL_VIEW_HEIGHT);
		[self addSubview:bgView];
		[bgView release];
        
        self.ipodActionToPerformOnScrollViewDeceleration = None;
        
        [self setupScrollView];
        [self setupAlbumArtworkView];
        [self setupScrollViewLabels];
        
        [self setupTapGestureRecognizer];
        
        [self setupiPodListeners];
        
        [self setupHeader];
    }
    return self;
}

#pragma mark Gesture Recognizer

- (void)onTap:(UITapGestureRecognizer *)tap
{
    //if (self.scrollView.isDragging){
    //    return;
    //}
    
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
        self.scrollView.transform = CGAffineTransformMakeScale(0.90, 0.90);
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
        [self setAlbumArtToNewImage:[itemArtwork imageWithSize:self.albumArt.bounds.size] animated:animated];
        
    } else {
        
        [self.header reset];
        
        self.songTitle.text = @"";
        self.songArtist.text = @"";
        self.songAlbum.text = @"";
        
        [self setAlbumArtToNewImage:nil animated:animated];
    }
}

- (void)setAlbumArtToNewImage:(UIImage *)image animated:(BOOL)animated
{
    UIImage *newAlbumArtImage = (image) ? image : DEFAULT_ARTWORK_IMAGE;
    
    if (animated){
        [UIView animateWithDuration:ALBUM_ART_ANIM_TIME / 2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.albumArt.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }completion:^(BOOL finished){
            [UIView animateWithDuration:ALBUM_ART_ANIM_TIME / 2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                self.albumArt.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }completion:nil];
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
        
        if (self.scrollView.contentOffset.x >= 40) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToNext;
        } else if (self.scrollView.contentOffset.x <= -40 ) { //in skip position
            self.ipodActionToPerformOnScrollViewDeceleration = SkipToPrevious;
        } else {
            self.ipodActionToPerformOnScrollViewDeceleration = None;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //self.rightActionLabel.text = @"";
    //self.leftActionLabel.text = @"";
    
    //if (!self.didSeekOnLastScrollViewTouch){
    
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
    
    
    
    //}
    
    //self.didSeekOnLastScrollViewTouch = NO;
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
    self.albumArt = [[UIImageView alloc] initWithImage:DEFAULT_ARTWORK_IMAGE];
    [self.scrollView addSubview:self.albumArt];
    self.albumArt.contentMode = UIViewContentModeScaleToFill;
    [UIView setSize:self.albumArt newSize:CGSizeMake(ALBUM_ART_SIZE, ALBUM_ART_SIZE)];
    [UIView setOriginX:self.albumArt newOrigin:ALBUM_ART_PADDING];
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
    
    //song albym
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
    CGRect rect = CGRectMake(0, 0, VIEW_WIDTH, VIEW_HEADER_HEIGHT);
    self.header = [[NCMusicGesturesHeader alloc] initWithFrame:rect];
    [self addSubview:self.header];
}

#pragma mark Cleanup

- (void)dealloc
{
    [[NCMusicGesturesView ipod] endGeneratingPlaybackNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    
    [self.scrollView removeGestureRecognizer:self.tapGestureRecognizer];
    [self.tapGestureRecognizer release];
    
    [self.albumArt release];
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
