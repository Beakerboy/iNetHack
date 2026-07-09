#import "EngineWrapper36.h"
#import "hack.h"

__weak id<NetHackEngineDelegate> _globalWindowDelegate = nil;

@implementation EngineWrapper36

- (void)setDelegate:(id<NetHackEngineDelegate>)delegate {
    _delegate = delegate;
    _globalWindowDelegate = delegate; // Assigns the global pointer
}

- (void)frameworkMain {
    main();
}
- (void)haptic_reset {
    haptic_reset()
}
@end
