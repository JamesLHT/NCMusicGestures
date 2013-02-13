//
//  NCMusicGesturesController.h
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-02-08.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "SpringBoard/BBWeeAppController.h"

#define VIEW_HEADER_HEIGHT 50
#define VIEW_HEIGHT 100

@interface NCMusicGesturesController : NSObject <BBWeeAppController>
{
    UIView *_view;
}

- (UIView *)view;

@end