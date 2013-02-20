//
//  NCMusicGesturesHeaderPageTwo.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "NCMusicGesturesHeaderPageTwo.h"
#import <Social/Social.h>
//#import "ViewController.h"
#import "NCMusicGesturesView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+UIViewExtensions.h"
#import "UIImage+UIImageExtensions.h"

#define IMAGE_SHUFFLE_ON [UIImage imageFromBundleWithName:@"white_shuffle.png"]
#define IMAGE_SHUFFLE_OFF [UIImage imageFromBundleWithName:@"grey_shuffle.png"]

#define IMAGE_REPEAT_ALL [UIImage imageFromBundleWithName:@"white_repeat.png"]
#define IMAGE_REPEAT_ONE [UIImage imageFromBundleWithName:@"white_repeat_one.png"]
#define IMAGE_REPEAT_OFF [UIImage imageFromBundleWithName:@"grey_repeat.png"]

#define IMAGE_TWITTER_OFF [UIImage imageFromBundleWithName:@"grey_twitter.png"]
#define IMAGE_TWITTER_ON [UIImage imageFromBundleWithName:@"white_twitter.png"]

#define IMAGE_FACEBOOK_OFF [UIImage imageFromBundleWithName:@"grey_facebook.png"]
#define IMAGE_FACEBOOK_ON [UIImage imageFromBundleWithName:@"white_facebook.png"]

#define IMAGE_DONATE [UIImage imageFromBundleWithName:@"white_donate.png"]

@interface NCMusicGesturesHeaderPageTwo()

@property (strong, nonatomic) UIViewController *shareViewController;

@property (strong, nonatomic) UIButton *shuffleButton;
@property (strong, nonatomic) UIButton *repeatButton;
@property (strong, nonatomic) UIButton *twitterButton;
@property (strong, nonatomic) UIButton *facebookButton;
@property (strong, nonatomic) UIButton *donateButton;

@property (assign, nonatomic) MPMusicPlayerController *ipod;

@end

@implementation NCMusicGesturesHeaderPageTwo

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        self.shareViewController = [[UIViewController alloc] init];
        self.shareViewController.view = self;
        
        [self setupButtons];
        
        [self updateTwitterButton];
        [self updateFacbookButton];
        
        [self.ipod beginGeneratingPlaybackNotifications];
        
        [self updateShuffleButtonToCurrentState];
        [self updateRepeateButtonToCurrentState];
    }
    return self;
}

#pragma mark iPod

- (MPMusicPlayerController *)ipod
{
    if (!_ipod){
        _ipod = [MPMusicPlayerController iPodMusicPlayer];
    }
    return _ipod;
}

- (void)shuffleButtonClicked
{
    switch ([self.ipod shuffleMode]) {
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
    switch ([self.ipod shuffleMode]) {
        case MPMusicShuffleModeOff:
            [self.shuffleButton setImage:IMAGE_SHUFFLE_OFF forState:UIControlStateNormal];
            break;
            
        case MPMusicShuffleModeSongs:
            [self.shuffleButton setImage:IMAGE_SHUFFLE_ON forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)repeateButtonClicked
{
    switch ([self.ipod repeatMode]) {
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
    
    [self updateRepeateButtonToCurrentState];
}

- (void)updateRepeateButtonToCurrentState
{
    switch ([self.ipod repeatMode]) {
        case MPMusicRepeatModeNone:
            [self.repeatButton setImage:IMAGE_REPEAT_OFF forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeAll:
            [self.repeatButton setImage:IMAGE_REPEAT_ALL forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeOne:
            [self.repeatButton setImage:IMAGE_REPEAT_ONE forState:UIControlStateNormal];
            
        default:
            break;
    }
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
        MPMediaItem *item = self.ipod.nowPlayingItem;
        
        if (item){
            NSString *songTitle = [item valueForProperty:MPMediaItemPropertyTitle];
            NSString *songArtist = [item valueForProperty:MPMediaItemPropertyArtist];
            
            MPMediaItemArtwork *itemArtwork = [item valueForProperty:MPMediaItemPropertyArtwork];
            UIImage *albumArtImage = [itemArtwork imageWithSize:itemArtwork.bounds.size];
            
            SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
            [composeViewController setInitialText:[NSString stringWithFormat:@"%@%@%@%@", @"I am listening to ", songTitle, @" by ", songArtist]];
            if (albumArtImage){
                [composeViewController addImage:albumArtImage];
            }
            
            [self.shareViewController presentViewController:composeViewController animated:YES completion:nil];
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

#pragma mark Setup

- (void)setupButtons
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
    
    
    NSInteger buttonWidth = (self.frame.size.width / 5);
    
    UIButton *returnButton = [[UIButton alloc] init];
    [UIView setSize:returnButton newSize:CGSizeMake(buttonWidth, self.frame.size.height)];
    [returnButton setImage:image forState:UIControlStateNormal];
    [self addSubview:returnButton];
    
    return returnButton;
}

#pragma mark Cleanup

- (void)dealloc
{
    [self.shareViewController release];
    
    [self.shuffleButton removeTarget:self action:@selector(shuffleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.shuffleButton release];
    
    [self.repeatButton removeTarget:self action:@selector(repeateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.repeatButton release];
    
    [self.twitterButton removeTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.twitterButton release];
    
    [self.facebookButton removeTarget:self action:@selector(facebookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.facebookButton release];
    
    [self.donateButton removeTarget:self action:@selector(donateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
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
