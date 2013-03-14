//
//  ViewController.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "ViewController.h"
#import "NCMusicGesturesView.h"

static ViewController *staticSelf;

@interface ViewController()

@property (strong, nonatomic) NCMusicGesturesView *musicGestures;

@end

@interface ViewController ()

@end

@implementation ViewController

+ (UIViewController *)mainViewController
{
    return staticSelf;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    staticSelf = self;
    
    self.musicGestures = [[NCMusicGesturesView alloc] init];
    [self.view addSubview:self.musicGestures.view];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self.musicGestures willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self.musicGestures didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.musicGestures release];
    [super dealloc];
}

@end
