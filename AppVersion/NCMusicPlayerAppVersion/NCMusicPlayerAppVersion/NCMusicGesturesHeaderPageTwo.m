//
//  NCMusicGesturesHeaderPageTwo.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-11.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "NCMusicGesturesHeaderPageTwo.h"
#import <Social/Social.h>
#import "ViewController.h"
#import "NCMusicGesturesView.h"
#import <MediaPlayer/MediaPlayer.h>
#import "UIView+UIViewExtensions.h"

@interface NCMusicGesturesHeaderPageTwo()

@property (readonly, nonatomic) ViewController *mainViewController;

@property (strong, nonatomic) UIButton *shuffleButton;
@property (strong, nonatomic) UIButton *repeatButton;
@property (strong, nonatomic) UIButton *twitterButton;
@property (strong, nonatomic) UIButton *facebookButton;
@property (strong, nonatomic) UIButton *donateButton;

@end

@implementation NCMusicGesturesHeaderPageTwo

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupButtons];
    }
    return self;
}

#pragma mark iPod

- (void)shuffleButtonClicked
{
    switch ([NCMusicGesturesView ipod].shuffleMode) {
        case MPMusicShuffleModeOff:
            [NCMusicGesturesView ipod].shuffleMode = MPMusicShuffleModeSongs;
            break;
            
        case MPMusicShuffleModeSongs:
            [NCMusicGesturesView ipod].shuffleMode = MPMusicShuffleModeOff;
            break;
            
        case MPMusicShuffleModeDefault:
            [NCMusicGesturesView ipod].shuffleMode = MPMusicShuffleModeOff;
            break;
            
        case MPMusicShuffleModeAlbums:
            [NCMusicGesturesView ipod].shuffleMode = MPMusicShuffleModeOff;
            break;
            
        default:
            break;
    }
    
    [self updateShuffleButtonToCurrentState];
}

- (void)updateShuffleButtonToCurrentState
{
    switch ([NCMusicGesturesView ipod].shuffleMode) {
        case MPMusicShuffleModeOff:
            [self.shuffleButton setTitle:@"OFF" forState:UIControlStateNormal];
            break;
            
        case MPMusicShuffleModeSongs:
            [self.shuffleButton setTitle:@"ON" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)repeateButtonClicked
{
    switch ([NCMusicGesturesView ipod].repeatMode) {
        case MPMusicRepeatModeNone:
            [NCMusicGesturesView ipod].repeatMode = MPMusicRepeatModeAll;
            break;
            
        case MPMusicRepeatModeAll:
            [NCMusicGesturesView ipod].repeatMode = MPMusicRepeatModeOne;
            break;
            
        case MPMusicRepeatModeOne:
            [NCMusicGesturesView ipod].repeatMode = MPMusicRepeatModeNone;
            break;
            
        case MPMusicShuffleModeDefault:
            [NCMusicGesturesView ipod].repeatMode = MPMusicRepeatModeNone;
            break;
            
        default:
            break;
    }
    
    [self updateRepeateButtonToCurrentState];

}

- (void)updateRepeateButtonToCurrentState
{
    switch ([NCMusicGesturesView ipod].repeatMode) {
        case MPMusicRepeatModeNone:
            [self.repeatButton setTitle:@"OFF" forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeAll:
            [self.repeatButton setTitle:@"ALL" forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeOne:
            [self.repeatButton setTitle:@"ONE" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }

}

- (ViewController *)mainViewController
{
    return [ViewController mainViewController];
}

- (void)twitterButtonClicked
{
    [self shareCurentSongWithServiceType:SLServiceTypeTwitter];
}

- (void)facebookButtonClicked
{
    [self shareCurentSongWithServiceType:SLServiceTypeFacebook];
}

- (void)donateButtonClicked
{
    NSURL *url = [ [ NSURL alloc ] initWithString: @"https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=pat%2esluth%40gmail%2ecom&lc=CA&item_name=Pat%20Sluth&no_note=0&currency_code=CAD&bn=PP%2dDonationsBF%3abtn_donateCC_LG%2egif%3aNonHostedGuest" ];
    [[UIApplication sharedApplication] openURL:url];
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
            
            SLComposeViewController *composeViewController = [SLComposeViewController composeViewControllerForServiceType:serviceType];
            [composeViewController setInitialText:[NSString stringWithFormat:@"%@%@%@%@", @"I am listening to ", songTitle, @" by ", songArtist]];
            if (albumArtImage){
                [composeViewController addImage:albumArtImage];
            }
            [self.mainViewController presentViewController:composeViewController animated:YES completion:nil];
        }
    }
    else
    {
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
    self.shuffleButton = [self createHeaderButton:@"Shuffle"];
    [UIView setOrigin:self.shuffleButton newOrigin:CGPointMake(0, 0)];
    [self.shuffleButton addTarget:self action:@selector(shuffleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupRepeatButton
{
    self.repeatButton = [self createHeaderButton:@"Repeat"];
    [UIView setOrigin:self.repeatButton newOrigin:CGPointMake(self.shuffleButton.frame.origin.x +
                                                              self.shuffleButton.frame.size.width, 0)];
    [self.repeatButton addTarget:self action:@selector(repeateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupTwitterButton
{
    self.twitterButton = [self createHeaderButton:@"Twitter"];
    [UIView setOrigin:self.twitterButton newOrigin:CGPointMake(self.repeatButton.frame.origin.x +
                                                               self.repeatButton.frame.size.width, 0)];
    [self.twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupFacebookButton
{
    self.facebookButton = [self createHeaderButton:@"Facebook"];
    [UIView setOrigin:self.facebookButton newOrigin:CGPointMake(self.twitterButton.frame.origin.x +
                                                                self.twitterButton.frame.size.width, 0)];
    [self.facebookButton addTarget:self action:@selector(facebookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setupDonateButton
{
    self.donateButton = [self createHeaderButton:@"Donate"];
    [UIView setOrigin:self.donateButton newOrigin:CGPointMake(self.facebookButton.frame.origin.x +
                                                              self.facebookButton.frame.size.width, 0)];
    [self.donateButton addTarget:self action:@selector(donateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *)createHeaderButton:(NSString *)title
{
    NSInteger buttonWidth = (self.frame.size.width / 5);
    
    UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [UIView setSize:returnButton newSize:CGSizeMake(buttonWidth, self.frame.size.height)];
    [returnButton setTitle:title forState:UIControlStateNormal];
    // [returnButton setImage:[UIImage imageNamed:@"twittershare"] forState:UIControlStateNormal];
    [self addSubview:returnButton];
    
    return returnButton;
}

#pragma mark Cleanup

- (void)dealloc
{
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
