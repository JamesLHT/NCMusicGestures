//
//  NCMusicGesturesHeader.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-12.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "NCMusicGesturesHeader.h"
#import "NCMusicGesturesView.h"
#import "NCMusicGesturesHeaderPageOne.h"
#import "NCMusicGesturesHeaderPageTwo.h"

#import "UIView+UIViewExtensions.h"
#import "StringFormatter.h"

@interface NCMusicGesturesHeader()

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) UIPageControl *scrollViewPageControl;

@property (strong, nonatomic) NCMusicGesturesHeaderPageOne *headerPageOne;
@property (strong, nonatomic) NCMusicGesturesHeaderPageTwo *headerPageTwo;

@end

@implementation NCMusicGesturesHeader

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupScrollView];
        [self setupiPodListeners];
    }
    return self;
}

#pragma mark iPod

- (void)oniPodStateChanged:(NSNotification *)notification
{
    switch ([NCMusicGesturesView ipod].playbackState) {
        case MPMusicPlaybackStateStopped:
            [self.headerPageOne stopUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStatePlaying:
            [self.headerPageOne startUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStatePaused:
            [self.headerPageOne stopUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStateInterrupted:
            [self.headerPageOne stopUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStateSeekingForward:
            [self.headerPageOne startUpdateSongPlaybackTimeTimer];
            break;
            
        case MPMusicPlaybackStateSeekingBackward:
            [self.headerPageOne startUpdateSongPlaybackTimeTimer];
            break;
            
        default:
            break;
    }
}

- (void)oniPodItemChanged:(NSNotification *)notification
{
    [self.headerPageOne checkSongTime];
}

- (void)setInfoFromMPMediaItem:(MPMediaItem *)item animated:(BOOL)animated
{
    NSInteger currentItemLength = [[[NCMusicGesturesView ipod].nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] integerValue];
    self.headerPageOne.songTotalTime.text = [StringFormatter formattedStringForDurationHMS:currentItemLength];
}

#pragma mark ScrollView

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    CGFloat pageWidth = scrollView.frame.size.width;
    float fractionalPage = scrollView.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    
    self.scrollViewPageControl.currentPage = page;
    [self.scrollViewPageControl updateCurrentPageDisplay];
    
    if (page == 0){
        self.scrollView.delaysContentTouches = NO;
    } else {
        self.scrollView.delaysContentTouches = YES;
    }
}

#pragma mark Setup

- (void)setupScrollView
{
    CGRect rect = CGRectMake(0, 0, 316, VIEW_HEADER_HEIGHT);
    
    self.scrollView = [[UIScrollView alloc] initWithFrame:rect];
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.delaysContentTouches = NO;
    self.scrollView.contentSize = CGSizeMake(rect.size.width * 2, rect.size.height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    [self addSubview:self.scrollView];
    
    self.scrollViewPageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(rect.origin.x, rect.origin.y, rect.size.width, 20)];
    [UIView setOriginY:self.scrollViewPageControl newOrigin:(self.scrollView.frame.origin.y +
                                                             self.scrollView.frame.size.height) - self.scrollViewPageControl.frame.size.height];
    self.scrollViewPageControl.numberOfPages = 2;
    [self insertSubview:self.scrollViewPageControl belowSubview:self.scrollView];
    
    CGRect rectTwo = CGRectMake(0, 0, 316, VIEW_HEADER_HEIGHT - 15);
    
    self.headerPageOne = [[NCMusicGesturesHeaderPageOne alloc] initWithFrame:rectTwo];
    [self.scrollView addSubview:self.headerPageOne];
    
    self.headerPageTwo = [[NCMusicGesturesHeaderPageTwo alloc] initWithFrame:
                          CGRectMake(rectTwo.origin.x + rectTwo.size.width, rectTwo.origin.y, rectTwo.size.width, rectTwo.size.height)];
    [self.scrollView addSubview:self.headerPageTwo];
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
    [self.headerPageOne reset];
}

- (void)dealloc
{
    [[NCMusicGesturesView ipod] endGeneratingPlaybackNotifications];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
    
    [self.headerPageOne release];
    [self.headerPageTwo release];
    [self.scrollView release];
    [self.scrollViewPageControl release];
    
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
