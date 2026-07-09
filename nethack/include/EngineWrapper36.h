#import <Foundation/Foundation.h>

typedef int winid;
@class Window;
@class NethackEvent;
@class NethackMenuItem;
@class NethackYnFunction;

@protocol NetHackEngineDelegate <NSObject>
- (void)clipAroundX:(int)x y:(int)y;
- (winid)createWindow:(int)type;
- (void)destroyWindow:(winid)wid;
- (void)displayFile:(NSString *)filename mustExist:(BOOL)e;
- (void)displayMenuWindow:(Window *)w;
- (void)displayWindowId:(winid)wid blocking:(BOOL)blocking;
- (void)displayYnQuestion:(NethackYnFunction *)yn;
- (void)doPlayerSelection;
- (void)endMenuForWindowWithId:(int)wid prompt:(const char *)prompt;
- (NethackEvent *)fetchNextInputEvent;
- (void)getLine:(char *)line prompt:(const char *)prompt;
- (void)postKeyEvent:(int)ch;
- (void)resetGlyphCache;
- (int)selectMenuForWindowWithId:(int)wid how:(int)how selectedItems:(struct menu_item **)selected;
- (void)showKeyboard:(BOOL)d;
- (void)updateScreen;
- (Window *)windowWithId:(winid)wid;

- (char)getDirectionInput;
- (int)getExtendedCommand;

- (void)setAnimFrame:(int)frame;
- (void)setGameInProgress:(BOOL)inProgress;

- (int)animFrame;

@end

@interface EngineWrapper36 : NSObject
@property (nonatomic, weak) id<NetHackEngineDelegate> delegate;
- (instancetype)initWithOptions:(NSString *)optionsString hackDir:(NSString *)hackDirPath;
- (void)main;
- (void)haptic_reset;
@end
