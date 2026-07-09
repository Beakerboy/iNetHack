#import <Foundation/Foundation.h>

typedef int winid;

@protocol NetHackEngineDelegate <NSObject>
- (winid)createWindowWithType:(int)type;
- (void)destroyWindowWithId:(winid)wid;
// ... add future migrated window functions here ...
@end

@interface EngineWrapper36 : NSObject
- (void)main;
- (void)haptic_reset;
@end
