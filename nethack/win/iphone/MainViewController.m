#import "MainViewController.h"
#import "func_tab.h"

// Declare the external C main function from this target's winiphone.m
extern int iphone_main(int argc, char **argv);
extern void save_currentstate(void);
extern int dosave(void);
extern char lock[]; 
@implementation MainViewController

- (void) runNativeEngineLoop {
    // This runs safely on the background thread spawned by the parent class
    char *argv[] = {"nethack36"};
    iphone_main(1, argv);
}

- (void)runNativeSaveCode {
    // This executes inside the 3.6 context perfectly
    save_currentstate();
}

- (void)runNativeTerminateCode {
    if (self.gameInProgress) {
        // Call the 3.6 C function directly
        dosave();
    } else {
        // Clean up the 3.6-specific lock files
        NSString *lockFile = [NSString stringWithCString:lock encoding:NSASCIIStringEncoding];
        if ([[NSFileManager defaultManager] fileExistsAtPath:lockFile]) {
            int fail = unlink(lock);
            NSCAssert1(!fail, @"Failed to unlink lock %s", lock);
        }
    }

}

- (TileSet *)mainViewRequiresAsciiTileSetWithTileSize:(CGSize)size {
    // Return the specific 3.6 engine tileset variant
    return [[[AsciiTileSet alloc] initWithTileSize:size] autorelease];
}

- (PlayerState *)playerState {
    PlayerState *state = [[[PlayerState alloc] init] autorelease];
    
    state.ux        = u.ux;
    state.uy        = u.uy;
    state.hp        = u.uhp;
    state.hpMax     = u.uhpmax;
    state.energy    = u.uen;
    state.energyMax = u.uenmax;
    state.mhmax     = u.mhmax;
    state.mh        = u.mh;
    state.mtimedone = u.mtimedone;
    state.uhp       = u.uhp;
    state.uhpmax    = u.uhpmax;
    
    return state;
}

- (int)maxGlyphConstant {
    return MAX_GLYPH;
}

- (BOOL)isPetGlyph:(int)glyph {
    return glyph_is_pet(glyph);
}

- (int)noGlyphConstant {
    return NO_GLYPH;
}

- (int) winInvenConstant {
    return WIN_INVEN;
}

- (int) bufferSize {
    return BUFSZ;
}


- (void *)allocateEngineMenuListBuffer {
    // Dynamically returns the exact memory size needed for this specific NetHack version
    return malloc(sizeof(menu_item));
}

- (void)populateMenuList:(void *)menuList withAmount:(int)amount identifier:(const void *)identifier {
    if (menuList) {
        // Explicitly typecast the anonymous void* back to the native C struct type
        menu_item *nativeList = (menu_item *)menuList;
        
        // Safely populate the internal fields for this NetHack version
        nativeList->count = amount;
        
        // NetHack's internal menu selection requires assigning the native union field
        // Cast the generic pointer back to the version-appropriate anything union assignment
        nativeList->item.a_void = (void *)identifier; 
    }
}

- (void)filterExtendedCommandsIntoNames:(NSMutableArray<NSString *> *)names 
                               indices:(NSMutableArray<NSNumber *> *)indices {
    int row = 0;
    struct ext_func_tab *f = extcmdlist;
    
    // Your exact while loop logic preserved natively!
    while (f++->ef_txt) {
        // Run your version-specific engine filters here (e.g., skip wizard mode items)
        BOOL shouldShow = YES;
        if (f->ef_txt == '?') { shouldShow = NO; }
        
        if (shouldShow) {
            // Translate the raw C-string to a safe Objective-C string for the UI target
            [names addObject:[NSString stringWithUTF8String:extcmdlist[row].ef_txt]];
            [indices addObject:[NSNumber numberWithInt:row]];
        }
        row++;
    }
}

- (char)extractInventoryLetterFromIdentifier:(const void *)identifier {
    if (identifier) {
        // Explicitly cast the generic pointer address back to the version-appropriate anything structural layout
        // In NetHack, menu identifiers are passed down as pointer addresses containing the union data
        const anything *nativeUnion = (const anything *)identifier;
        return nativeUnion->a_char;
    }
    return '\0';
}

@end
