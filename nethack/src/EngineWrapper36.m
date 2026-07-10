#import "EngineWrapper36.h"
#import "hack.h"
#import "winiphone.h"
#import "RoleSelectionController.h"

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

- (void)resetPlayerChoices:(NetHackPlayerResetType)type {
    // Replicates your exact working fall-through cascade safely inside the framework
    switch (type) {
        case RESET_ROLE:
            flags.initrole = ROLE_NONE; // ROLE_NONE resolves natively to -1
            [[fallthrough]];
        case RESET_RACE:
            flags.initrace = ROLE_NONE;
            [[fallthrough]];
        case RESET_GENDER:
            flags.initgend = ROLE_NONE;
            [[fallthrough]];
        case RESET_ALIGNMENT:
            flags.initalign = ROLE_NONE;
            break;
    }
}

- (void) doPlayerSelectionOnUIThread:(id)obj {
	RoleSelectionController* roleSelector = [RoleSelectionController roleSelectorWithNavigationController:self.navigationController];
	roleSelector.delegate = self;
	[roleSelector start];
}
@end
