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
#import <MediaPlayer/MediaPlayer.h>

#define BUTTON_PADDING 5

@interface NCMusicGesturesHeaderPageTwo()

@property (readonly, nonatomic) ViewController *mainViewController;

@property (readonly, nonatomic) MPMusicPlayerController *ipod;

@property (strong, nonatomic) UIButton *twitterButton;
@property (strong, nonatomic) UIButton *facebookButton;
@property (strong, nonatomic) UIButton *donateButton;

@end

@implementation NCMusicGesturesHeaderPageTwo

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        CGRect twitterButtonRect = CGRectMake(BUTTON_PADDING, 0, self.frame.size.height, self.frame.size.height);
        self.twitterButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.twitterButton.frame = twitterButtonRect;
        self.twitterButton.titleLabel.text = @"Twtr";
       // [self.twitterButton setImage:[UIImage imageNamed:@"twittershare"] forState:UIControlStateNormal];
        [self.twitterButton addTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.twitterButton];
        
        CGRect facebookButtonRect = CGRectMake(self.twitterButton.frame.origin.x +
                                               self.twitterButton.frame.size.width +
                                               BUTTON_PADDING,
                                               0,
                                               self.frame.size.height,
                                               self.frame.size.height);
        self.facebookButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.facebookButton.frame = facebookButtonRect;
        self.facebookButton.titleLabel.text = @"FB";
        //[self.facebookButton setImage:[UIImage imageNamed:@"facebookshare"] forState:UIControlStateNormal];
        [self.facebookButton addTarget:self action:@selector(facebookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.facebookButton];
        
        CGRect doneButtonRect = CGRectMake(self.facebookButton.frame.origin.x +
                                               self.facebookButton.frame.size.width +
                                               BUTTON_PADDING,
                                               0,
                                               self.frame.size.height,
                                               self.frame.size.height);
        self.donateButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        self.donateButton.frame = doneButtonRect;
        self.donateButton.titleLabel.text = @"Donate";
        //[self.donateButton setImage:[UIImage imageNamed:@"facebookshare"] forState:UIControlStateNormal];
        [self.donateButton addTarget:self action:@selector(donateButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.donateButton];
    }
    return self;
}

- (ViewController *)mainViewController
{
    return [ViewController mainViewController];
}

- (MPMusicPlayerController *)ipod
{
    return [MPMusicPlayerController iPodMusicPlayer];
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
            [self.mainViewController presentViewController:composeViewController animated:YES completion:nil];
        }
    }
    else
    {
    }
}

- (void)dealloc
{
    [self.twitterButton removeTarget:self action:@selector(twitterButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.twitterButton release];
    
    [self.facebookButton removeTarget:self action:@selector(facebookButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.facebookButton release];
    
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
