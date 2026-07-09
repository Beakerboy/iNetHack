#import <Foundation/Foundation.h>

typedef int winid;

@protocol NetHackEngineDelegate <NSObject>
- (winid)createWindowWithType:(int)type;
- (void)destroyWindowWithId:(winid)wid;
- (void)updateScreen;
- (int)animFrame;
- (void)setAnimFrame:(int)frame;
- (void)doPlayerSelection;

// ... add future migrated window functions here ...
@end

@interface EngineWrapper36 : NSObject
- (void)main;
- (void)haptic_reset;
@end
