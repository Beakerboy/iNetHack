#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface EngineWrapper36 : NSObject

/**
 * Initializes the NetHack 3.6 engine with required game paths.
 * @param savePath The directory where game saves and bones files should live.
 * @param assetPath The directory containing the 3.6 loose assets (dungeon, ram, etc).
 */
- (instancetype)initWithSavePath:(NSString *)savePath assetPath:(NSString *)assetPath;

/**
 * Starts the core NetHack game loop (calls the internal C moveloop).
 * Note: Since NetHack's loop blocks the thread, you should call this on a background thread.
 */
- (void)runGameLoop;

/**
 * Sends a single keystroke or command from the iOS UI down into the 3.6 C engine.
 */
- (void)sendInputCharacter:(char)input;

@end

NS_ASSUME_NONNULL_END
