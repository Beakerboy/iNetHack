/*
 *  iphone.c
 *  iNetHack
 *
 *  Created by dirk on 6/26/09.
 *  Copyright 2009 Dirk Zimmermann. All rights reserved.
 *
 */

//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 2 of the License only.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import "winiphone.h"
#import "EngineWrapper36.h"
#import <UIKit/UIKit.h>
#import <CoreHaptics/CoreHaptics.h>
#import <CommonCrypto/CommonDigest.h>

#include <stdio.h>
#include <fcntl.h>
#include "dlb.h"
#include "hack.h"
#include "func_tab.h"
#include "date.h"

#ifdef __APPLE__
#include "TargetConditionals.h"
#endif

extern __weak id<NetHackEngineDelegate> _globalWindowDelegate;

#define kOptionUsername (@"username")
#define kOptionAutopickup (@"autopickup")
#define kOptionPickupTypes (@"pickupTypes")
#define kOptionTravel (@"travel")
#define kOptionPickupThrown (@"pickupThrown")
#define kOptionWizard (@"wizard")
#define kOptionAutokick (@"autokick")
#define kOptionTime (@"time")
#define kOptionShowExp (@"showexp")
#define kOptionAutoDig (@"autodig")

#undef DEFAULT_WINDOW_SYS
#define DEFAULT_WINDOW_SYS "iphone"

static CHHapticEngine *hapticEngine = nil;
boolean dohaptics = TRUE;

boolean winiphone_autokick = TRUE;
boolean winiphone_clickable_tiles = FALSE;
boolean winiphone_travel = TRUE;

struct window_procs iphone_procs = {
"iphone",
WC_COLOR|WC_HILITE_PET|
WC_ASCII_MAP|WC_TILED_MAP|
WC_FONT_MAP|WC_TILE_FILE|WC_TILE_WIDTH|WC_TILE_HEIGHT|
WC_PLAYER_SELECTION|WC_SPLASH_SCREEN,
0L,
{0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0},
iphone_init_nhwindows,
iphone_player_selection,
iphone_askname,
iphone_get_nh_event,
iphone_exit_nhwindows,
iphone_suspend_nhwindows,
iphone_resume_nhwindows,
iphone_create_nhwindow,
iphone_clear_nhwindow,
iphone_display_nhwindow,
iphone_destroy_nhwindow,
iphone_curs,
iphone_putstr,
genl_putmixed,
iphone_display_file,
iphone_start_menu,
iphone_add_menu,
iphone_end_menu,
iphone_select_menu,
genl_message_menu,	  /* no need for X-specific handling */
iphone_update_inventory,
iphone_mark_synch,
iphone_wait_synch,
#ifdef CLIPPING
iphone_cliparound,
#endif
#ifdef POSITIONBAR
donull,
#endif
iphone_print_glyph,
iphone_raw_print,
iphone_raw_print_bold,
iphone_nhgetch,
iphone_nh_poskey,
iphone_nhbell,
iphone_doprev_message,
iphone_yn_function,
iphone_getlin,
iphone_get_ext_cmd,
iphone_number_pad,
iphone_delay_output,
#ifdef CHANGE_COLOR	 /* only a Mac option currently */
donull,
donull,
#endif
/* other defs that really should go away (they're tty specific) */
iphone_start_screen,
iphone_end_screen,
iphone_outrip,
genl_preference_update,
genl_getmsghistory,
genl_putmsghistory,
genl_status_init,
genl_status_finish,
genl_status_enablefield,
genl_status_update,
genl_can_suspend_no,
};

// ScreenTimer object to handle updating map for animated tilesets.
@interface ScreenTimer : NSObject
@end

@implementation ScreenTimer

void timerAction() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        while (true) {
            // Create a strong local reference to prevent the weak delegate 
            // from disappearing mid-loop
            id<NetHackEngineDelegate> strongDelegate = _globalWindowDelegate;
            
            if (strongDelegate) {
                // UI updates MUST run on the Main Thread to prevent iOS crashes
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongDelegate updateScreen];
                });
                
                // 2. Read and toggle the animation frame via the delegate
                if ([strongDelegate animFrame] == 0) {
                    [strongDelegate setAnimFrame:2];
                } else {
                    [strongDelegate setAnimFrame:0];
                }
            } else {
                // If the app is tearing down or the delegate is nil, kill the thread loop
                break; 
            }
            
            usleep(500000); // sleep for 0.5 seconds.
        }
    });
}
@end

@implementation WinIPhone

+ (void) triggerInitialize {
	// do nothing
}

+ (void) initialize {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
								@"YES", kOptionAutopickup,
								@"$\"=/!?+", kOptionPickupTypes,
                                @"YES", kOptionTravel,
                                @"YES", kOptionPickupThrown,
								@"YES", kOptionAutokick,
								@"YES", kOptionShowExp,
								@"YES", kOptionTime,
								@"YES", kOptionAutoDig,
								nil]];
}

/**
 * @brief Determines whether a specific external command should be displayed in the UI.
 *
 * @details Evaluates a command from the global `extcmdlist` against game state and flag 
 * filters. It blocks wizard commands for non-wizards, excludes the '?' help command, 
 * filters unavailable commands, and enforces autocomplete availability.
 *
 * @param row The index of the command to evaluate within the `extcmdlist` array.
 *
 * @return `true` if the command meets all visibility criteria; otherwise `false`.
 *
 * @note This function references global state variables `extcmdlist` and `wizard`.
 */
- (Boolean) showExtCmd:(int) row {
    struct ext_func_tab *efp = &extcmdlist[row];

    if (!efp->ef_txt)
        return false;

    int wizc;
    /* skip wizard mode commands if not in wizard mode */
    wizc = (efp->flags & WIZMODECMD) != 0;
    if (wizc && !wizard)
        return false;

    uchar original = ((char) (0x7F & (efp->key)));
    if (original == efp->key && (!wizard && wizc)) {
        switch (original) {
            /* show a few special case commands */
            case 'X': /* twoweapon */
            case 'N': /* name */
            case 'n':
                break;
            default: return false;
        }
    }

    if (original == '?')
        return false; // don't bother showing #?
    if ((efp->flags & CMD_NOT_AVAILABLE) != 0)
        return false;
    /* if hiding non-autocomplete commands, skip such */
    if ((efp->flags & AUTOCOMPLETE) == 0)
        return false;
    return true;
}
@end

NSString *nativeMD5HexForFile(NSString *path) {
    // 1. Read the entire file into an NSData block in a single step
    NSData *fileData = [NSData dataWithContentsOfFile:path];
    if (!fileData || fileData.length == 0) {
        return nil;
    }
    
    // 2. Execute CommonCrypto's one-shot hashing function
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(fileData.bytes, (CC_LONG)fileData.length, digest);
    
    // 3. Convert the resulting raw bytes into a lowercase hex string
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [output appendFormat:@"%02x", digest[i]];
    }
    
    return output;
}

FILE *iphone_fopen(const char *filename, const char *mode) {
	NSString *filenameStr = [NSString stringWithCString:filename encoding:NSASCIIStringEncoding];
    NSString *path = [[NSBundle mainBundle] pathForResource:filenameStr 
                                            ofType:@"" 
                                            inDirectory:@"nethack36"];
    const char *pathc = [path fileSystemRepresentation];
    FILE *file = fopen(pathc, mode);
	return file;
}

// These must be defined but are not used (they handle keyboard interrupts).
void intron() {}
void introff() {}

int dosuspend() {
	return 0;
}

int dosh() {
	return 0;
}

void error(const char *s, ...) {
	exit(0);
}

void regularize(char *s) {
	register char *lp;

	for (lp = s; *lp; lp++) {
		if (*lp == '.' || *lp == ':')
			*lp = '_';
	}
}

int child(int wt) {
	return 0;
}

#pragma mark nethack window system API

void iphone_init_nhwindows(int* argc, char** argv) {
	iflags.window_inited = TRUE;
}

void iphone_player_selection() {
	[_globalWindowDelegate doPlayerSelection];
}

void iphone_askname() {
	if (!wizard) {
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSString *name = [defaults objectForKey:kOptionUsername];

		if (!name || name.length == 0) {
			name = [NSFullUserName() capitalizedString];
			[defaults setObject:name forKey:kOptionUsername];
		}
		// issue 33 patch provided by ciawal
		if(![name getCString:plname maxLength:PL_NSIZ encoding:NSASCIIStringEncoding]) {
			// If the conversion fails attempt to perform a lossy conversion instead
			NSData* lossyName = [name dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
			[lossyName getBytes:plname length:PL_NSIZ-1];
			plname[lossyName.length] = 0;
		}
        if (!plname[0]) {
            strcpy(plname, "Mobile User");
            [defaults setObject:@"Mobile User" forKey:kOptionUsername];
        }
	} else {
		strcpy(plname, "wizard");
	}
}

// Replace with donull?
void iphone_get_nh_event() {
}

void iphone_exit_nhwindows(const char *str) {
	// please don't touch this without previous discussion dirkz
	NSLog(@"iphone_exit_nhwindows %s", str);
}

void iphone_suspend_nhwindows(const char *str) {
	NSLog(@"iphone_suspend_nhwindows %s", str);
}

// Replace with donull?
void iphone_resume_nhwindows() {
	NSLog(@"iphone_resume_nhwindows");
}

winid iphone_create_nhwindow(int type) {
    if (_globalWindowDelegate) {
        return [_globalWindowDelegate createWindow:type];
    }
    return -1; 
}

void iphone_clear_nhwindow(winid wid) {
	[_globalWindowDelegate clearWindowWithId:wid];
}

void iphone_display_nhwindow(winid wid, BOOLEAN_P block) {
	[_globalWindowDelegate displayWindowId:wid blocking:block ? YES:NO];
}

void iphone_destroy_nhwindow(winid wid) {
    if (_globalWindowDelegate) {
        [_globalWindowDelegate destroyWindow:wid];
    }
}

void iphone_curs(winid wid, int x, int y) {
}

void iphone_putstr(winid wid, int attr, const char *text) {
    if (_globalWindowDelegate) {
        [_globalWindowDelegate writeStringToWindowWithId:wid attribute:attr text:text];
    }
}

void iphone_display_file(const char *filename, BOOLEAN_P must_exist) {
	[_globalWindowDelegate displayFile:[NSString stringWithCString:filename encoding:NSASCIIStringEncoding]
									 mustExist:must_exist ? YES : NO];
}

void iphone_start_menu(winid wid) {
    if (_globalWindowDelegate) {
        [_globalWindowDelegate callStartMenu:wid];
    }
}

void iphone_add_menu(winid wid, int glyph, const ANY_P *identifier,
                     CHAR_P accelerator, CHAR_P group_accel, int attr, 
                     const char *str, BOOLEAN_P presel) {
    if (_globalWindowDelegate) {
        [_globalWindowDelegate addItemToMenuWindowWithId:wid
                                                   glyph:glyph
                                              identifier:identifier
                                             accelerator:accelerator
                                              groupAccel:group_accel
                                               attribute:attr
                                                   title:str
                                             preselected:presel];
    }
}

void iphone_end_menu(winid wid, const char *prompt) {
    if (_globalWindowDelegate) {
        [_globalWindowDelegate endMenuForWindowWithId:wid prompt:prompt];
    }
}

int iphone_select_menu(winid wid, int how, menu_item **selected) {
    if (_globalWindowDelegate) {
        // Route directly through the delegate boundary
        return [_globalWindowDelegate selectMenuForWindowWithId:wid how:how selectedItems:selected];
    }
    return -1; // Fallback cancellation if no UI is attached
}

// Replace with donull?
void iphone_update_inventory() {
}

// Replace with donull?
void iphone_mark_synch() {
}

// Replace with donull?
void iphone_wait_synch() {
}

void iphone_cliparound(int x, int y) {
    if (_globalWindowDelegate) {
        [_globalWindowDelegate clipAroundX:x y:y];
    }
}

void iphone_cliparound_window(winid wid, int x, int y) {
	NSLog(@"iphone_cliparound_window %d %d,%d", wid, x, y);
}

void iphone_print_glyph(winid wid, XCHAR_P x, XCHAR_P y, int glyph, int ignore) {
    if (_globalWindowDelegate) {
        // Pass coordinates and glyph directly through the pipeline boundary
        [_globalWindowDelegate drawGlyphToWindowWithId:wid atX:x y:y glyph:glyph];
    }
}

void iphone_raw_print(const char *str) {
	if (strlen(str)) {
		NSLog(@"raw_print %s", str);
		winid window = create_nhwindow(NHW_TEXT);
		putstr(window, ATR_NONE, str);
		display_nhwindow(window, true);
		destroy_nhwindow(window);
	}
}

void iphone_raw_print_bold(const char *str) {
	if (strlen(str)) {
		NSLog(@"raw_print_bold %s", str);
		winid window = create_nhwindow(NHW_TEXT);
		putstr(window, ATR_BOLD, str);
		display_nhwindow(window, true);
		destroy_nhwindow(window);
	}
}

int iphone_nhgetch() {
	NSLog(@"iphone_nhgetch");
	return 0;
}

/**
 * @brief Coordinates the main blocking loop that waits for user touch or keyboard input.
 *
 * This function handles input routing from NetHack's core engine layer. It queries the 
 * Objective-C delegate boundary to fetch the next interaction event block. If an event 
 * is captured, it unpacks the grid coordinates and click properties back into NetHack's 
 * internal reference pointers.
 *
 * @param[out] x    Pointer to an integer where the target grid column of the tap will be written.
 * @param[out] y    Pointer to an integer where the target grid row of the tap will be written.
 * @param[out] mod  Pointer to an integer representing the cursor modifier (e.g., CLICK_1).
 *
 * @return The ASCII character value or engine token mapping to the key pressed or action performed.
 *         Returns 027 (ASCII Escape) as a fallback signature if the delegate is uninitialized.
 */
/**
 * @brief Waits for the next user event and unpacks its primitives directly.
 * @param x Pointer where the horizontal grid column will be written.
 * @param y Pointer where the vertical grid row will be written.
 * @return The integer/ASCII value of the pressed key.
 */
int iphone_nh_poskey(int *x, int *y, int *mod) {
    if (_globalWindowDelegate) {
        // Set the native NetHack modifier
        *mod = CLICK_1; 
        
        // Pass the target pointers directly down to the delegate to populate
        return [_globalWindowDelegate fetchNextInputEventReturningX:x y:y];
    }
    
    // Safety fallback if no delegate exists
    *x = 0;
    *y = 0;
    *mod = 0;
    return 027; // Escape key
}

void iphone_nhbell() {}

// message log is accessible from the menu, so we don't really need it here
int iphone_doprev_message() {
	//NSLog(@"iphone_doprev_message");
	return 0;
}

// expands stuff like 'a-c' into 'abc'
static NSString *expandInventoryLetters(NSString *lets) {
	NSMutableString *res = [NSMutableString string];
	char lastChar;
	BOOL isRange = NO;
	for (int i = 0; i < lets.length; ++i) {
		char c = [lets characterAtIndex:i];
		if (isRange) {
			for (char ch = lastChar+1; ch <= c; ++ch) {
				[res appendString:[NSString stringWithFormat:@"%c", ch]];
			}
			isRange = NO;
		} else if (c == '-' && lastChar) {
			isRange = YES;
		} else {
			[res appendString:[NSString stringWithFormat:@"%c", c]];
			lastChar = c;
		}
	}
	//NSLog(@"expandInventoryLetters(@%) -> %@", lets, res);
	return res;
}

char iphone_yn_function(const char *question, const char *choices, CHAR_P def) {
    if (!_globalWindowDelegate) {
        return def;
    }

    [_globalWindowDelegate updateScreen];

    // Handle choices being provided (Simple Yes/No questions)
    if (choices) {
        NSString *s = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
        // Retain your working bypass logic for automated saving saves
        if ([s isEqualToString:@"Really save?"] || [s isEqualToString:@"Overwrite the old file?"]) {
            return 'y';
        } 
        return [_globalWindowDelegate displayYnQuestion:question choices:choices defaultChoice:def];
    }

    // Handle choices being NULL (Complex inventory/direction prompts)
    return [_globalWindowDelegate handleComplexQueryPrompt:question defaultChoice:def];
}

void iphone_getlin(const char *prompt, char *line) {
	//NSLog(@"iphone_getlin %s", prompt);
	[_globalWindowDelegate getLine:line prompt:prompt];
}

int iphone_get_ext_cmd() {
	return [_globalWindowDelegate getExtendedCommand];
}

void iphone_number_pad(int num) {
	//NSLog(@"iphone_number_pad %d", num);
}

void iphone_delay_output() {
	//NSLog(@"iphone_delay_output");
    usleep(50000); // Standard delay so animations are visible.
}

void iphone_start_screen() {
	//NSLog(@"iphone_start_screen");
}

void iphone_end_screen() {
	//NSLog(@"iphone_end_screen");
}

void iphone_outrip(winid wid, int how, long ignore) {
	//NSLog(@"iphone_outrip %d", wid);
}

#pragma mark options

void iphone_init_options() {
    [WinIPhone triggerInitialize];
    iflags.use_color = TRUE;
    flags.runmode = RUN_STEP;
    flags.verbose = TRUE;
    iflags.toptenwin = TRUE;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    //iNethack2: pickup_thrown setting
    flags.pickup_thrown = [defaults boolForKey:kOptionPickupThrown];
    
    flags.pickup = [defaults boolForKey:kOptionAutopickup];
    NSString *pickupTypes = [defaults objectForKey:kOptionPickupTypes];
    if (flags.pickup && pickupTypes) {
        NSMutableString *tmp = [NSMutableString string];
        for (int i = 0; i < pickupTypes.length; ++i) {
            int oc_sym = def_char_to_objclass([pickupTypes characterAtIndex:i]);
            if (![tmp containsChar:oc_sym]) {
                [tmp appendFormat:@"%c", oc_sym];
            }
        }
        [tmp getCString:flags.pickup_types maxLength:MAXOCLASSES encoding:NSASCIIStringEncoding];
    }

#if TARGET_IPHONE_SIMULATOR
    wizard = YES; //iNethack2 YES for sim usually..
#else */
    wizard = [defaults boolForKey:kOptionWizard];

#endif

    winiphone_autokick = [defaults boolForKey:kOptionAutokick];
    //iNethack2: travel setting. not the travelcmd setting as that would prevent clickable tiles from working.
    winiphone_travel = [defaults boolForKey:kOptionTravel];
    flags.showexp = [defaults boolForKey:kOptionShowExp];
    flags.time = [defaults boolForKey:kOptionTime];
    flags.autodig = [defaults boolForKey:kOptionAutoDig];
    flags.lit_corridor = true;
    NSLog(@"Wizard is %d", wizard);
}

void iphone_override_options() {
	// somehow the flags seem to be erased (after restore?)
	// so just call it again
	iphone_init_options();
}

void process_options(int argc, char *argv[]) {
}

#pragma mark main

void iphone_remove_stale_files() {
	NSString *pattern = [NSString stringWithFormat:@"%d%s", getuid(),
						 [NSUserName() cStringUsingEncoding:NSASCIIStringEncoding]];

    NSArray *filelist= [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"." error:nil];
    
	for (NSString *filename in filelist) {
		if ([filename startsWithString:pattern]) {
			int fail = unlink([filename fileSystemRepresentation]);
			if (!fail) {
				NSLog(@"removed %@", filename);
			} else {
				NSLog(@"failure to remove %@", filename);
			}
		}
	}
}

void
getlock(void)
{
	int fd;
	int pid = getpid(); /* Process ID */

	set_levelfile_name(lock, 0);

	const char* fq_lock = fqname(lock, LEVELPREFIX, 1);
	if ((fd = open(lock, O_RDWR | O_EXCL | O_CREAT, 0644)) == -1) {
        //char c = yn("There are files from a game in progress. Recover?");
        char c = 'y'; // 2.1.0+: autoload checkpoint file to work smoothly with new saving method.
		if (c != 'y' && c != 'Y') {
			int fail = unlink(lock);
			if (!fail) {
				iphone_remove_stale_files();
				fd = open(lock, O_RDWR | O_EXCL | O_CREAT, 0644);
				delete_savefile();
			} else {
				panic("Failed to unlink %s", lock);
			}
		} else {
			// Try to recover
			if(!recover_savefile()) {
// iNethack36: let's just silently ignore it.
//				int fail = unlink(lock);
//				NSCAssert1(!fail, @"Failed to unlink lock %s", lock);
//				panic("Couldn't recover old game.");
                iphone_remove_stale_files();
                fd = open(lock, O_RDWR | O_EXCL | O_CREAT, 0644);
                delete_savefile();
			} else {
				set_levelfile_name(lock, 0);
				fd = open(fq_lock, O_RDWR | O_EXCL | O_CREAT, 0644);
			}
		}
	}
	
	if (write(fd, (char *)&pid, sizeof (pid)) != sizeof (pid))  {
		raw_printf("Could not lock the game %s.", lock);
		panic("Disk locked?");
	}
	close (fd);
}

void iphone_test_main() {
	// place for threaded tests
}

void iphone_test_endianness() {
	NSString *filename = @"endianness";
	const char *cFilename = [filename fileSystemRepresentation];
	int someInt = 42;
	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
	int fd = open(cFilename, O_CREAT | O_WRONLY, S_IRUSR | S_IWUSR);
	write(fd, &someInt, sizeof(someInt));
	close(fd);
	NSLog(@"wrote %d", someInt);

	char buffer[4];
	fd = open(cFilename, O_RDONLY);
	read(fd, buffer, sizeof(buffer));
	close(fd);
	NSLog(@"read %d %d %d %d", buffer[0], buffer[1], buffer[2], buffer[3]);
	[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
}

void iphone_will_load_bones(const char *bonesid) {
	//NSLog(@"load bones %s", bonesid);
	NSString *src = [NSString stringWithFormat:@"./bon%s", bonesid]; //iNethack2 prepending with ./
	NSString *dest = [NSString stringWithFormat:@"./bon%s.bad", bonesid]; //iNethack2 prepending with ./
	NSString *md5 = nativeMD5HexForFile(src);
	NSError *error = nil;
	[md5 writeToFile:dest atomically:YES encoding:NSASCIIStringEncoding error:&error];
}

void iphone_finished_bones(const char *bonesid) {
	//NSLog(@"finished bones %s", bonesid);
	NSString *dest = [NSString stringWithFormat:@"bon%s.bad", bonesid];
	NSError *error = nil;
	[[NSFileManager defaultManager] removeItemAtPath:dest error:&error];
}
//iNethack2: pass along the glyph cache reset
void iphone_reset_glyph_cache(void) {
	[_globalWindowDelegate resetGlyphCache];
}

// Reset haptic engine so it is recreated next time.
void haptic_reset() {
    hapticEngine = nil;
}

// Trigger haptic feedback when damaged.
void iphone_haptic(int haptictype) {
    dohaptics = [[NSUserDefaults standardUserDefaults] floatForKey:@"haptics"];
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"haptics"] == nil) {
        // Possible they haven't updated settings since this option was added. Default is true.
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"haptics"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        dohaptics = TRUE;
    }
    if (!dohaptics) {
        return;
    }

    if (@available(iOS 13.0, *)) { // Core Haptics requires iOS 13 or later
        if (!hapticEngine) {  // Create the engine only once
            // Check if the device supports haptics
            if (!CHHapticEngine.capabilitiesForHardware.supportsHaptics) {
                NSLog(@"Haptics not supported on this device");
                dohaptics = FALSE;
                return;
            }

            NSError *error = nil;
            
            hapticEngine = [[CHHapticEngine alloc] initAndReturnError:&error];
            if (!hapticEngine) {
                NSLog(@"Failed to create haptic engine: %@", error);
                dohaptics = FALSE;
                return; // Early return if engine creation fails
            }
            [hapticEngine startAndReturnError:&error];
            if (error) {
                NSLog(@"Failed to start haptic engine: %@", error);
                dohaptics = FALSE;
                hapticEngine = nil; // Reset if start fails. Important!
                return;
            }
        }

        NSError *error = nil;
        CHHapticEvent *event = nil;
        CHHapticEventParameter *intensity;
        CHHapticEventParameter *sharpness;
        if (haptictype == HAPTIC_VIBRATING) {
            intensity = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:1.0];
            sharpness = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.2];
            event = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous parameters:@[intensity, sharpness] relativeTime:0.0 duration:0.6];
        } else {
            intensity = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticIntensity value:1.0];
            sharpness = [[CHHapticEventParameter alloc] initWithParameterID:CHHapticEventParameterIDHapticSharpness value:0.5];
            event = [[CHHapticEvent alloc] initWithEventType:CHHapticEventTypeHapticContinuous parameters:@[intensity, sharpness] relativeTime:0.0 duration:0.2];
        }
        CHHapticPattern *pattern = [[CHHapticPattern alloc] initWithEvents:@[event] parameterCurves:@[] error:&error];
                if (pattern) {
                    id<CHHapticPatternPlayer> player = [hapticEngine createPlayerWithPattern:pattern error:&error];
                    if (error) {
                        NSLog(@"Error creating haptic player: %@", error.localizedDescription);
                        return;
                    }
                    // Start the player
                    [player startAtTime:0 error:&error];
                    if (error) {
                        NSLog(@"Error starting haptic player: %@", error.localizedDescription);
                    }
                } else {
                    NSLog(@"Failed to create haptic pattern: %@", error);
                }
    } else {
        // Use simple method.
        UINotificationFeedbackGenerator *generator = [[UINotificationFeedbackGenerator alloc] init];
        [generator notificationOccurred:UINotificationFeedbackTypeSuccess];
    }
}

boolean
check_version_64(version_data, filename, complain)
struct version_info *version_data;
const char *filename;
boolean complain;
{
    unsigned long sanity2;
#if __LP64__
    sanity2=VERSION_SANITY2_64;
#else
    sanity2=VERSION_SANITY2;
#endif
    
    if (
#ifdef VERSION_COMPATIBILITY
        version_data->incarnation < VERSION_COMPATIBILITY ||
        version_data->incarnation > VERSION_NUMBER
#else
        version_data->incarnation != VERSION_NUMBER
#endif
        ) {
        if (complain)
            pline("Version mismatch for file \"%s\".", filename);
        return FALSE;
    } else if (
#ifndef IGNORED_FEATURES
               version_data->feature_set != VERSION_FEATURES ||
#else
               (version_data->feature_set & ~IGNORED_FEATURES) !=
               (VERSION_FEATURES & ~IGNORED_FEATURES) ||
#endif
               version_data->entity_count != VERSION_SANITY1 /*||
               version_data->struct_sizes != sanity2*/) {
        if (complain)
            pline("Configuration incompatibility for file \"%s\".",
                  filename);
        return FALSE;
    }
    return TRUE;
}

/* this used to be based on file date and somewhat OS-dependant,
 but now examines the initial part of the file's contents */
boolean
uptodate_64(fd, name)
int fd;
const char *name;
{
    int rlen;
    struct version_info vers_info;
    boolean verbose = name ? TRUE : FALSE;
    
    rlen = read(fd, (genericptr_t) &vers_info, sizeof vers_info);
    minit();		/* ZEROCOMP */
    if (rlen == 0) {
        if (verbose) {
            pline("File \"%s\" is empty?", name);
            wait_synch();
        }
        return FALSE;
    }
    if (!check_version_64(&vers_info, name, verbose)) {
        if (verbose) wait_synch();
        return FALSE;
    }
    return TRUE;
}

void
store_version_64(fd)
int fd;
{
#if __LP64__
    const static struct version_info version_data = {
        VERSION_NUMBER, VERSION_FEATURES,
        VERSION_SANITY1, VERSION_SANITY2_64
    };
#else
    const static struct version_info version_data = {
        VERSION_NUMBER, VERSION_FEATURES,
        VERSION_SANITY1, VERSION_SANITY2
    };
#endif
    bufoff(fd);
    /* bwrite() before bufon() uses plain write() */
    bwrite(fd,(genericptr_t)&version_data,(unsigned)(sizeof version_data));
    bufon(fd);
    return;
}

// iNetack added function copied from sys/unix/unixmain.c
unsigned long
sys_random_seed()
{
    unsigned long seed = 0L;
    unsigned long pid = (unsigned long) getpid();
    boolean no_seed = TRUE;
#ifdef DEV_RANDOM
    FILE *fptr;

    fptr = fopen(DEV_RANDOM, "r");
    if (fptr) {
        fread(&seed, sizeof (long), 1, fptr);
        has_strong_rngseed = TRUE;  /* decl.c */
        no_seed = FALSE;
        (void) fclose(fptr);
    } else {
        /* leaves clue, doesn't exit */
        paniclog("sys_random_seed", "falling back to weak seed");
    }
#endif
    if (no_seed) {
        seed = (unsigned long) getnow(); /* time((TIME_type) 0) */
        /* Quick dirty band-aid to prevent PRNG prediction */
        if (pid) {
            if (!(pid & 3L))
                pid -= 1L;
            seed *= pid;
        }
    }
    return seed;
}



int main() {
	int argc = 0;
	char **argv = NULL;
    
    ScreenTimer *screenTimer = [[ScreenTimer alloc] init];
    [screenTimer timerAction];
    

	
	// from macmain.c, enables special levels like sokoban
	x_maze_max = COLNO-1;
	if (x_maze_max % 2) {
		x_maze_max--;
	}
	y_maze_max = ROWNO-1;
	if (y_maze_max % 2) {
		y_maze_max--;
	}

	hackpid = getpid();
	
	choose_windows(DEFAULT_WINDOW_SYS); /* choose a default window system */
	initoptions();			   /* read the resource file */
	init_nhwindows(&argc, argv);		   /* initialize the window system */
	process_options(argc, argv);	   /* process command line options or equiv */
	iphone_init_options();

    NSString* logFilePath =	[[NSString alloc] initWithCString:LOGFILE encoding:NSASCIIStringEncoding];

    logFilePath = [NSString stringWithFormat:@"./%@", logFilePath]; //iNethack2 -- fix for iOS8.. needs full path
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:logFilePath]) {
		[[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
	}
	[logFilePath release];

	check_recordfile("");

	dlb_init();
	vision_init();
	display_gamewindows();		   /* create & display the game windows */

	Sprintf(lock, "%d%s", getuid(), [NSUserName() cStringUsingEncoding:NSASCIIStringEncoding]);
	getlock();

	register int fd;
    bool restored = false;
	if ((fd = restore_saved_game()) >= 0) {
#ifdef WIZARD
		/* Since wizard is actually flags.debug, restoring might
		 * overwrite it.
		 */
		boolean remember_wiz_mode = wizard;
        restored = true;
#endif
		//(void) chmod(fq_save,0);	/* disallow parallel restores */
		(void) signal(SIGINT, (SIG_RET_TYPE) done1);
#ifdef NEWS
		if(iflags.news) {
		    display_file(NEWS, FALSE);
		    iflags.news = FALSE; /* in case dorecover() fails */
		}
#endif
		pline("Restoring save file...");
		mark_synch();	/* flush output */
		if(!dorecover(fd))
			goto not_recovered;
#ifdef WIZARD
		if(!wizard && remember_wiz_mode) wizard = TRUE;
#endif
		check_special_room(FALSE);
		
		if (discover || wizard) {
			if(yn("Do you want to keep the save file?") == 'n') {
			    (void) delete_savefile();
			}
		}
	} else {
	not_recovered:
        restored = false;
		player_selection();
		newgame();
		//wd_message();
        set_wear(0);
		(void) pickup(1);
	}
	
	iphone_override_options();
	if (_globalWindowDelegate) {
	    [_globalWindowDelegate setGameInProgress:YES];
	}
	moveloop(restored);
	if (_globalWindowDelegate) {
	    [_globalWindowDelegate setGameInProgress:NO];
	}
	exit(EXIT_SUCCESS);
}

int
custom_mapglyph(glyph, ochar, ocolor, ospecial, x, y, flag)
int glyph, flag, *ocolor, x, y, *ochar;
unsigned *ospecial;
{
    return mapglyph(glyph, &ochar, &ocolor, &ospecial, x, y, flag);
}
