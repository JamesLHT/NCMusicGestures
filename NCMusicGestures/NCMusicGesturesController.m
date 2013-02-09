//
//  NCMusicGesturesController.m
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-02-08.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NCMusicGesturesController.h"
#import "NSMusicGesturesView.h"
#import "UIView+UIViewExtensions.h"

#define BACKGROUND_CAP_VALUE 5

#define VIEW_X_OFFSET 2
#define VIEW_WIDTH 316
#define TOTAL_VIEW_HEIGHT (VIEW_HEADER_HEIGHT + VIEW_HEIGHT)

@interface NCMusicGesturesController()

@property (readwrite, nonatomic) NSMusicGesturesView *musicController;

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
	[_view release];
    [_musicController release];
	[super dealloc];
}

- (UIView *)view
{
	if (_view == nil)
	{
		_view = [[UIView alloc] initWithFrame:CGRectMake(VIEW_X_OFFSET, 0, VIEW_WIDTH, TOTAL_VIEW_HEIGHT)];
		UIImage *bg = [[UIImage imageWithContentsOfFile:@"/System/Library/WeeAppPlugins/NCMusicGestures.bundle/WeeAppBackground.png"]
                       stretchableImageWithLeftCapWidth:BACKGROUND_CAP_VALUE topCapHeight:BACKGROUND_CAP_VALUE];
		UIImageView *bgView = [[UIImageView alloc] initWithImage:bg];
		bgView.frame = CGRectMake(0, 0, VIEW_WIDTH, TOTAL_VIEW_HEIGHT);
		[_view addSubview:bgView];
		[bgView release];
        
        self.musicController.hidden = NO;
	}

	return _view;
}

- (NSMusicGesturesView *)musicController
{
    if (!_musicController){
        _musicController = [[NSMusicGesturesView alloc] initWithFrame:_view.frame];
        [_view addSubview:_musicController];
        [UIView setOrigin:_musicController newOrigin:CGPointZero];
    }
    
    return _musicController;
}

- (float)viewHeight
{
    return TOTAL_VIEW_HEIGHT;
}

@end