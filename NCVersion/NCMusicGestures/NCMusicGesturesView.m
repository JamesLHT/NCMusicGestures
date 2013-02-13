//
//  NCMusicGesturesView.m
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-02-08.
//
//

#import "NCMusicGesturesView.h"
#import "NCMusicGesturesController.h"
#import "UIView+UIViewExtensions.h"
#import <MediaPlayer/MediaPlayer.h>

#define ALBUM_ART_ANIM_TIME 0.5
#define ALBUM_ART_PADDING 10
#define ALBUM_ART_SIZE 85

#define DEFAULT_ARTWORK_IMAGE [UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/NCMusicGestures.bundle/blankalbumart.png"]

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
@property (nonatomic) MPMusicPlayerController *ipod;

@property (strong, nonatomic) UISlider *timelineScrubber;

@end

@implementation NCMusicGesturesView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
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
        if (self.ipod.playbackState == MPMusicPlaybackStatePaused ||
            self.ipod.playbackState == MPMusicPlaybackStateStopped){
            [self.ipod play];
            [self performPlayPauseAnimation];
        } else if (self.ipod.playbackState == MPMusicPlaybackStatePlaying){
            [self.ipod pause];
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

- (MPMusicPlayerController *)ipod
{
    return [MPMusicPlayerController iPodMusicPlayer];
}

- (void)oniPodItemChanged:(NSNotification *)notification
{
    /*if (![NSThread isMainThread]){
     [self performSelectorOnMainThread:@selector(oniPodItemChanged:) withObject:notification waitUntilDone:NO];
     }*/
    
    MPMusicPlayerController *mp = notification.object;
    MPMediaItem *item = mp.nowPlayingItem;
    
    [self setInfoFromMPMediaItem:item animated:YES];
}

- (void)setInfoFromMPMediaItem:(MPMediaItem *)item animated:(BOOL)animated
{
    if (item){
        self.songTitle.text = [item valueForProperty:MPMediaItemPropertyTitle];
        self.songArtist.text = [item valueForProperty:MPMediaItemPropertyArtist];
        self.songAlbum.text = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
        
        MPMediaItemArtwork *itemArtwork = [item valueForProperty:MPMediaItemPropertyArtwork];
        if (itemArtwork){
            
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
                                    [self setAlbumArtToNewImage:[itemArtwork imageWithSize:self.albumArt.bounds.size]];
                                } completion:nil];
            } else {
                [self setAlbumArtToNewImage:[itemArtwork imageWithSize:self.albumArt.bounds.size]];
            }
        }
    }
}

- (void)setAlbumArtToNewImage:(UIImage *)image
{
    if (image){
        self.albumArt.image = image;
    } else {
        self.albumArt.image = DEFAULT_ARTWORK_IMAGE;
    }
}

- (void)beginSeekingForward
{
    if (self.ipod.playbackState != MPMusicPlaybackStateSeekingBackward){
        [self.ipod beginSeekingForward];
    }
}

- (void)beginSeekingBackwards
{
    if (self.ipod.playbackState != MPMusicPlaybackStateSeekingForward){
        [self.ipod beginSeekingBackward];
    }
}

- (void)endSeeking
{
    if (self.ipod.playbackState == MPMusicPlaybackStateSeekingBackward || self.ipod.playbackState == MPMusicPlaybackStateSeekingForward){
        [self.ipod endSeeking];
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
    /*
     self.songTitle.text = [NSString stringWithFormat:@"%f", self.scrollView.contentOffset.x];
     
     float forwardPosition = ((self.forwardIndicator.frame.origin.x - self.scrollView.frame.size.width)
     + self.scrollView.contentOffset.x) + self.forwardIndicator.frame.size.width;
     float forwardPercentage = (forwardPosition - self.forwardIndicator.frame.size.width) / self.forwardIndicator.frame.size.width;
     self.forwardIndicator.alpha = forwardPercentage;
     self.songArtist.text = [NSString stringWithFormat:@"%f", self.forwardIndicator.alpha];
     
     if (!self.scrollView.isDecelerating){ //we are still dragging
     
     if (forwardPercentage >= 1.0 && forwardPercentage < 1.8) { //in skip position
     self.ipodActionToPerformOnScrollViewDeceleration = SkipToNext;
     self.forwardIndicator.image = SKIP_FORWARD_IMAGE;
     [self endSeeking];
     } else if (forwardPercentage >= 1.8){ //in fast forward position
     self.ipodActionToPerformOnScrollViewDeceleration = None;
     self.forwardIndicator.image = SEEK_FORWARD_IMAGE;
     [self beginSeekingForward];
     self.didSeekOnLastScrollViewTouch = YES;
     } else {
     [self endSeeking];
     self.ipodActionToPerformOnScrollViewDeceleration = None;
     }
     }*/
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self endSeeking];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    //self.rightActionLabel.text = @"";
    //self.leftActionLabel.text = @"";
    
    //if (!self.didSeekOnLastScrollViewTouch){
    
    if (self.ipod.playbackState == MPMusicPlaybackStatePlaying ||
        self.ipod.playbackState == MPMusicPlaybackStatePaused){
        switch (self.ipodActionToPerformOnScrollViewDeceleration) {
            case SkipToNext:
                
                [self.ipod skipToNextItem];
                
                break;
                
            case SkipToPrevious:
                
                [self.ipod skipToPreviousItem];
                
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

- (UILabel *)createScrollViewLabel
{
    UILabel *l = [[UILabel alloc] init];
    l.backgroundColor = [UIColor clearColor];
    l.textColor = [UIColor whiteColor];
    l.textAlignment = NSTextAlignmentLeft;
    l.adjustsFontSizeToFitWidth = YES;
    [self.scrollView addSubview:l];
    [l release];
    
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
    
    [self.ipod beginGeneratingPlaybackNotifications];
}

- (void)setupHeader
{
    self.timelineScrubber = [[UISlider alloc] init];
    [self addSubview:self.timelineScrubber];
    [UIView setSize:self.timelineScrubber newSize:CGSizeMake(self.frame.size.width - (50 * 2), 50)];
    [UIView setOriginX:self.timelineScrubber newOrigin:50];
    [self.timelineScrubber addTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
}

- (void)onTimelineValueChange:(UISlider *)slider
{
    NSInteger currentItemLength = [[self.ipod.nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    NSInteger newPlaybackTime = currentItemLength * slider.value;
    [self.ipod setCurrentPlaybackTime:newPlaybackTime];
}

#pragma mark Cleanup

- (void)dealloc
{
    [self.scrollView removeGestureRecognizer:self.tapGestureRecognizer];
    [self.tapGestureRecognizer dealloc];
    
    [self.albumArt dealloc];
    [self.songTitle dealloc];
    [self.songArtist dealloc];
    [self.songAlbum dealloc];
    
    [self.scrollView dealloc];
    [self.timelineScrubber removeTarget:self action:@selector(onTimelineValueChange:) forControlEvents:UIControlEventValueChanged];
    [self.timelineScrubber dealloc];
    
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
