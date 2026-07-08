#import <Foundation/Foundation.h>

@protocol NetHackEngineDelegate <NSObject>
- (int)createWindowWithType:(int)type;
- (void)destroyWindowWithId:(int)wid;
// ... add future migrated window functions here ...
@end

@interface EngineWrapper36 : NSObject
- (void)main;
- (void)haptic_reset;
@end
