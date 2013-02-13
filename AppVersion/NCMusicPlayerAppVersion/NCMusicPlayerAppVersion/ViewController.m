//
//  ViewController.m
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import "ViewController.h"
#import "NCMusicGesturesView.h"

@interface ViewController ()

@end

@implementation ViewController

+ (ViewController *)mainViewController
{
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    UIViewController *rootViewController = window.rootViewController;
    return (ViewController *)rootViewController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NCMusicGesturesView *musicGestures = [[NCMusicGesturesView alloc] init];
    [self.view addSubview:musicGestures];
    [musicGestures release];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
