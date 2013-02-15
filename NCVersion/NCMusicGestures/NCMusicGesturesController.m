//
//  NCMusicGesturesController.m
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-02-08.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NCMusicGesturesController.h"
#import "NCMusicGesturesView.h"
#import "UIView+UIViewExtensions.h"

#define BACKGROUND_CAP_VALUE 5

#define VIEW_X_OFFSET 2
#define VIEW_WIDTH 316
#define TOTAL_VIEW_HEIGHT (VIEW_HEADER_HEIGHT + VIEW_HEIGHT)

@interface NCMusicGesturesController()

@property (readwrite, nonatomic) NCMusicGesturesView *musicGestures;

@end

@implementation NCMusicGesturesController

-(id)init
{
	if ((self = [super init]))
	{
	}

	return self;
}

-(void)dealloc
{
    [_musicGestures release];
	[_view release];
	[super dealloc];
}

- (UIView *)view
{
	if (_view == nil)
	{
		_view = [[UIView alloc] initWithFrame:CGRectMake(VIEW_X_OFFSET, 0, VIEW_WIDTH, TOTAL_VIEW_HEIGHT)];
        
        self.musicGestures = [[NCMusicGesturesView alloc] initWithFrame:_view.frame];
        [self.view addSubview:self.musicGestures];
	}

	return _view;
}

- (float)viewHeight
{
    return TOTAL_VIEW_HEIGHT;
}

@end