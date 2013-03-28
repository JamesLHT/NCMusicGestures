//
//  NCMusicGesturesController.h
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-03-14.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SpringBoard/BBWeeAppController.h"

#define VIEW_HEADER_HEIGHT 50
#define VIEW_HEIGHT 100

#define BACKGROUND_CAP_VALUE 5

#define VIEW_X_OFFSET 2
#define TOTAL_VIEW_HEIGHT (VIEW_HEADER_HEIGHT + VIEW_HEIGHT)

@interface NCMusicGesturesController : NSObject <BBWeeAppController>
{
    UIView *_view;
}

- (UIView *)view;

@end