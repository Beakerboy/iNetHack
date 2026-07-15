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

+ (NSString *)universalMoneyString {
    return [NSString stringWithFormat:@"%d %s ($)", (int) money_cnt(invent), currency(u.umoney0)];
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

- (void)launchPlayerSelectionWizard:(UINavigationController *)navController {
    // Force view rendering tasks safely onto the main thread layout
    dispatch_async(dispatch_get_main_queue(), ^{
        if (navController) {
            // Instantiate your controller cleanly inside the framework target
            RoleSelectionController *roleSelector = [RoleSelectionController roleSelectorWithNavigationController:navController];
            
            // Bind the selection delegate back to the EngineWrapper instance 
            // so the framework internal systems handle parsing the results
            roleSelector.delegate = (id)self; 
            
            // Fire off the character picker wizard screens
            [roleSelector start];
        }
    });
}

- (BOOL)isPlayerOnRogueLevel {
    if (u.uz.dlevel && Is_rogue_level(&u.uz)) {
        return YES;
    }
    return NO;

- (BOOL)isPlayerPosition:(int)x pos2:(int)y {
    return u.ux == x && u.uy == y;
}

- (UIColor *)playerHealthColor {
    int hp100;
    if (u.mtimedone) {
        hp100 = u.mhmax ? u.mh * 100 / u.mhmax : 100;
    } else {
        hp100 = u.uhpmax ? u.uhp * 100 / u.uhpmax : 100;
    }

    const CGFloat colorValue = 0.7f;
    const CGFloat alphaValue = 0.5f;

    if (hp100 > 75) {
        // Green
        return [UIColor colorWithRed:0.0f green:colorValue blue:0.0f alpha:alphaValue];
    } else if (hp100 > 50) {
        // Yellow (Red + Green)
        return [UIColor colorWithRed:colorValue green:colorValue blue:0.0f alpha:alphaValue];
    } else {
        // Red
        return [UIColor colorWithRed:colorValue green:0.0f blue:0.0f alpha:alphaValue];
    }
}

- (BOOL)isPetGlyph:(int)glyph {
    return glyph_is_pet(glyph);
}

-(BOOL)isClickableTiles {
    return winiphone_clickable_tiles;
}
@end
