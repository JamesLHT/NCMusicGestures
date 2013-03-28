//
//  ViewController.m
//  MusicPlayerBug
//
//  Created by Pat Sluth on 2013-03-27.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()

@property (assign, nonatomic) MPMusicPlayerController *ipod;
@property (retain, nonatomic) IBOutlet UIButton *playButton;
@property (retain, nonatomic) IBOutlet UIButton *repeatButton;

@end

@implementation ViewController

- (MPMusicPlayerController *)ipod
{
    if (!_ipod){
        _ipod = [MPMusicPlayerController iPodMusicPlayer];
    }
    return _ipod;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updatePlayButtonToCurrentState];
    [self updateRepeatButtonToCurrentState];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (IBAction)playButtonPressed:(UIButton *)sender
{
    if (self.ipod.playbackState == MPMusicPlaybackStatePaused || self.ipod.playbackState == MPMusicPlaybackStateStopped){
        [self.ipod play];
    } else if (self.ipod.playbackState == MPMusicPlaybackStatePlaying){
        [self.ipod pause];
    }
    
    [self updatePlayButtonToCurrentState];
}

- (void)updatePlayButtonToCurrentState
{
    if (self.ipod.playbackState == MPMusicPlaybackStatePaused || self.ipod.playbackState == MPMusicPlaybackStateStopped){
        [self.playButton setTitle:@"paused" forState:UIControlStateNormal];
    } else if (self.ipod.playbackState == MPMusicPlaybackStatePlaying){
        [self.playButton setTitle:@"playing" forState:UIControlStateNormal];
    }
}

- (IBAction)repeatButtonPressed:(UIButton *)sender
{
    switch (self.ipod.repeatMode) {
        case MPMusicRepeatModeDefault:
            [self.ipod setRepeatMode:MPMusicRepeatModeNone];
            break;
            
        case MPMusicRepeatModeNone:
            [self.ipod setRepeatMode:MPMusicRepeatModeAll];
            break;
            
        case MPMusicRepeatModeAll:
            [self.ipod setRepeatMode:MPMusicRepeatModeOne];
            break;
            
        case MPMusicRepeatModeOne:
            [self.ipod setRepeatMode:MPMusicRepeatModeNone];
            break;
            
        default:
            break;
    }
    
    [self updateRepeatButtonToCurrentState];
}

- (void)updateRepeatButtonToCurrentState
{
    switch (self.ipod.repeatMode) {
        case MPMusicRepeatModeDefault:
            [self.repeatButton setTitle:@"repeat default" forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeNone:
            [self.repeatButton setTitle:@"repeat none" forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeAll:
            [self.repeatButton setTitle:@"repeat all" forState:UIControlStateNormal];
            break;
            
        case MPMusicRepeatModeOne:
            [self.repeatButton setTitle:@"repeat one" forState:UIControlStateNormal];
            break;
            
        default:
            break;
    }
}

- (void)dealloc {
    [_playButton release];
    [_repeatButton release];
    [super dealloc];
}
@end
