//
//  NCMusicGesturesView.h
//  NCMusicPlayerAppVersion
//
//  Created by Pat Sluth on 2013-02-10.
//  Copyright (c) 2013 Pat Sluth. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NCMusicGesturesController.h"

#define VIEW_HEADER_HEIGHT 50
#define VIEW_HEIGHT 100

@interface NCMusicGesturesView : UIViewController <UIScrollViewDelegate, UIAlertViewDelegate, UIPickerViewDelegate, UIPickerViewDataSource>

@property (assign, nonatomic) NCMusicGesturesController *controller;

- (void)onViewDidAppear;
- (void)onViewDidDissappear;

@end
