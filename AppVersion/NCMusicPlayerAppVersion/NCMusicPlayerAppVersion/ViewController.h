//
//  ViewController.h
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>

@class NCMusicGesturesView;

@interface ViewController : UIViewController

@property (readonly, retain) NCMusicGesturesView *musicGestures;

+ (UIViewController *)mainViewController;

@end
