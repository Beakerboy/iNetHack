#import <Foundation/Foundation.h>

typedef int winid;
@class Window;
@class NethackEvent;
@class NethackYnFunction;

@protocol NetHackEngineDelegate <NSObject>
- (winid)createWindowWithType:(int)type;
- (void)destroyWindowWithId:(winid)wid;
- (void)displayFile:(NSString *)filename mustExist:(BOOL)e;
- (void)displayMenuWindow:(Window *)w;
- (void)displayWindowId:(winid)wid blocking:(BOOL)blocking;
- (void)displayYnQuestion:(NethackYnFunction *)yn;
- (void)doPlayerSelection;
- (NethackEvent *)fetchNextInputEvent;
- (char)getDirectionInput;
- (int)getExtendedCommand;
- (void)getLine:(char *)line prompt:(const char *)prompt;
- (void)postKeyEvent:(int)ch;
- (void)resetGlyphCache;
- (void)setAnimFrame:(int)frame;
- (void)setGameInProgress:(BOOL)inProgress;
- (void)showKeyboard:(BOOL)d;
- (void)updateScreen;
- (Window *)windowWithId:(winid)wid;

- (int)animFrame;

@end

@interface EngineWrapper36 : NSObject
- (void)main;
- (void)haptic_reset;
@end
