
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@protocol PlayListViewDelegate;

@interface PlayListView : UIView <UITableViewDataSource,UITableViewDelegate>

@property (assign) id <PlayListViewDelegate> playListViewDelegate;

@end

@protocol PlayListViewDelegate <NSObject>

- (void)selectedPlayList:(MPMediaPlaylist*)playlist;

@end
