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
        
        [self updateTwitterButton];
        [self updateFacbookButton];
        
        [self updateShuffleButtonToCurrentState];
        [self updateRepeateButtonToCurrentState];
    }
    return self;
}

#pragma mark iPod

- (void)shuffleButtonClicked
{
    switch ([NCMusicGesturesView ipod].shuffleMode) {
        case MPMusicShuffleModeOff:
            [[NCMusicGesturesView ipod] setShuffleMode:MPMusicShuffleModeSongs];
            break;
            
        case MPMusicShuffleModeSongs:
            [[NCMusicGesturesView ipod] setShuffleMode:MPMusicShuffleModeOff];
            break;
            
        case MPMusicShuffleModeDefault:
            [[NCMusicGesturesView ipod] setShuffleMode:MPMusicShuffleModeOff];
            break;
            
        case MPMusicShuffleModeAlbums:
            [[NCMusicGesturesView ipod] setShuffleMode:MPMusicShuffleModeOff];
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
    switch ([NCMusicGesturesView ipod].repeatMode) {
        case MPMusicRepeatModeNone:
            [[NCMusicGesturesView ipod] setRepeatMode:MPMusicRepeatModeAll];
            break;
            
        case MPMusicRepeatModeAll:
            [[NCMusicGesturesView ipod] setRepeatMode:MPMusicRepeatModeOne];
            break;
            
        case MPMusicRepeatModeOne:
            [[NCMusicGesturesView ipod] setRepeatMode:MPMusicRepeatModeNone];
            break;
            
        case MPMusicShuffleModeDefault:
            [[NCMusicGesturesView ipod] setRepeatMode:MPMusicRepeatModeNone];
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

- (ViewController *)mainViewController
{
    return [ViewController mainViewController];
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
