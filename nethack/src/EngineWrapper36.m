#import "EngineWrapper36.h"
#import "hack.h"
#import "winiphone.h"

__weak id<NetHackEngineDelegate> _globalWindowDelegate = nil;

@implementation EngineWrapper36

- (void)setDelegate:(id<NetHackEngineDelegate>)delegate {
    _delegate = delegate;
    _globalWindowDelegate = delegate; // Assigns the global pointer
}

- (void)frameworkMain {
    main();
}
- (void)hapticReset {
    haptic_reset();
}

- (void)saveCurrentstate {
    save_currentstate();
}

- (int)doSave {
    return dosave();
}

- (void)cleanUpLockFile {
    if (self.delegate) {
        // Pass the internal 'lock' string out to the app delegate safely
        [self.delegate unlinkLockFile:lock];
    }
}
@end
