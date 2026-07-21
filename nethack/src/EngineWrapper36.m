#import "EngineWrapper36.h"
#import "hack.h"
#import "winiphone.h"
#import "RoleSelectionController.h"

__weak id<NetHackEngineDelegate> _globalWindowDelegate = nil;

static inline void custom_mapglyph(int glyph, int *ochar, int *ocolor, unsigned *ospecial, int x, int y, int fallback) {
    mapglyph(glyph, ochar, ocolor, ospecial, x, y);
}

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

-(BOOL)isGameOver {
    return program_state.gameover == 1;
}

- (char)displayInventoryWithLetters:(NSString *)letters wantReply:(BOOL)wantReply {
    // Safely handle nil or empty strings to prevent C crashes
    const char *cLetters = (letters.length > 0) ? [letters cStringUsingEncoding:NSASCIIStringEncoding] : "";
    
    // Cast the Objective-C BOOL safely to the NetHack engine's boolean expected type
    boolean cWantReply = wantReply ? 1 : 0;
    
    // Execute the underlying engine code
    return display_inventory(cLetters, cWantReply);
}

/**
 * @brief Returns the number of rows to display in a given section of the table view.
 *
 * @details This method dynamically filters the global external command list (`extcmdlist`)
 * based on visibility rules defined by `showExtCmd:`. It populates `filteredExtCmd`
 * and `filteredExtCmdIndex` with the valid items and their original indices.
 *
 * @param tableView The table view requesting this information.
 * @param section   The index number identifying a section in @p tableView.
 *
 * @return The number of rows (filtered commands) to display in the specified section.
 *
 * @note This method mutates state by reinitializing and repopulating data source arrays.
 *       It assumes a single-section table view as the @p section parameter is not explicitly checked.
 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	struct ext_func_tab *f = extcmdlist;
	NSMutableArray *filteredExtCmd = [NSMutableArray array];
    NSMutableArray *filteredExtCmdIndex = [NSMutableArray array];
    filteredExtCmd = [[NSMutableArray alloc] init];
    filteredExtCmdIndex = [[NSMutableArray alloc] init];
    int filtered = 0;
    int row = 0;
	while (f++->ef_txt) {
        filtered++;
        if (![self showExtCmd:row]) {
            // Filter out items that shouldn't be displayed: wizard mode, regular commands, etc.
            filtered--;
        } else {
            NSValue *value = [NSValue valueWithBytes:&extcmdlist[row] objCType:@encode(struct ext_func_tab)];
            [filteredExtCmd addObject:value];
            [filteredExtCmdIndex addObject:[NSNumber numberWithInt: row]];
        }
        row++;
	}
    return filtered;
}

- (void)setUseColorFlag:(BOOL)useColor {
    iflags.use_color = useColor ? TRUE : FALSE;
}

- (BOOL)isGlyphObject:(int)g {
    return glyph_is_object(g);
}
@end

#import "EngineWrapper36.h"
#include "hack.h" // Gives access to the real 'struct you' and global 'u'

NHEPlayerState * NHEGetPlayerState(void) {
    // We cast NetHack's global 'u' struct to our public wrapper type.
    // Because ux and uy are the first fields in both, this is 100% memory-safe.
    return (NHEPlayerState *)&u;
}
