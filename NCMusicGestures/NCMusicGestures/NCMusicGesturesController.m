//
//  NCMusicGesturesController.m
//  NCMusicGestures
//
//  Created by Pat Sluth on 2013-03-14.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NCMusicGesturesController.h"

#import "NCMusicGesturesView.h"

#import "UIImage+UIImageExtensions.h"
#import "UIView+UIViewExtensions.h"

@interface NCMusicGesturesController()

@property (strong, nonatomic) NCMusicGesturesView *musicGestures;

@property (readwrite, nonatomic) BOOL nowPlayingItem;

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
    [self.musicGestures release];
    //[self.b release];
    //[self.controller release];
	[_view release];
	[super dealloc];
}

- (void)viewDidAppear
{
    CGSize mainSize = self.view.superview.frame.size;
    _view.frame = CGRectMake(0, 0, mainSize.width, TOTAL_VIEW_HEIGHT);
    
    
    if (!self.musicGestures){
        self.musicGestures = [[NCMusicGesturesView alloc] init];
        [_view addSubview:self.musicGestures.view];
    }
    
    self.musicGestures.view.frame = CGRectMake(VIEW_X_OFFSET, 0,
                                               _view.frame.size.width - (VIEW_X_OFFSET * 2),
                                               _view.frame.size.height);
    [self.musicGestures onViewDidAppear];
}

- (void)viewDidDisappear
{
    [self.musicGestures onViewDidDissappear];
}

- (UIView *)view
{
	if (_view == nil)
	{
		_view = [[UIView alloc] initWithFrame:CGRectMake(VIEW_X_OFFSET, 0,
                                                         _view.superview.frame.size.width,
                                                         TOTAL_VIEW_HEIGHT)];
        if (!self.musicGestures){
            self.musicGestures = [[NCMusicGesturesView alloc] init];
            self.musicGestures.controller = self;
            [_view addSubview:self.musicGestures.view];
        }
    }
    
	return _view;
}

- (float)viewHeight
{
    //if (self.nowPlayingItem){
        return TOTAL_VIEW_HEIGHT;
    //} else {
    //    return 20;
    //}
}

- (void)updateStateToNowPlayingItemIsNull:(BOOL)exists
{
    /*self.nowPlayingItem = exists;
    
    if (!_view){
        return;
    }
    
    float height = [self viewHeight];
    
    [UIView setSizeY:_view newSize:height];*/
}

@end