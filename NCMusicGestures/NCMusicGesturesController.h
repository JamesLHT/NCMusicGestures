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

@interface NCMusicGesturesController : NSObject <BBWeeAppController>
{
    UIView *_view;
}

- (UIView *)view;

@end