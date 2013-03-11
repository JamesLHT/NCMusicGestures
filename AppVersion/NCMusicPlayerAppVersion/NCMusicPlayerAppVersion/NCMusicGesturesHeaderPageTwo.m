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
