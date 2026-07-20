/**
 * @file EngineWrapper36.h
 * @brief Public interface boundary for the NetHack core gameplay engine framework.
 *
 * This file serves as the modular bridge separating the low-level, global C execution state
 * of NetHack 3.6 from the high-level, event-driven Objective-C/Swift application layer. 
 * It encapsulates thread orchestration, lifecycle flags, and input/output routing.
 *
 * @author Kevin Nowaczyk
 * @date 2026
 */

#import <UIKit/UIKit.h>

/**
 * @brief A unique integer identifier mapped to a graphical or text window tracking context.
 * 
 * Satisfies standard vanilla NetHack window tracking layouts without exposing raw core header layers.
 */
typedef int winid;
typedef struct menu_item NHEMenuItem; 
static const int NHE_COLNO = 80;
static const int NHE_ROWNO = 21;
static const int NHE_NO_GLYPH = 5991;
static const int NHE_WIN_INVEN = 4;
static const int NHE_MAX_GLYPH = 5991;
static const int NHE_BUFSZ = 256;

typedef NS_ENUM(NSInteger, NHEWindowType) {
    NHEW_MESSAGE = 1,
    NHEW_STATUS  = 2,
    NHEW_MAP     = 3,
    NHEW_MENU    = 4,
    NHEW_TEXT    = 5
};

typedef NS_ENUM(NSInteger, NHEMenuSelectionMode) {
    NHE_PICK_NONE = 0, 
    NHE_PICK_ONE  = 1,
    NHE_PICK_ANY  = 2
};

#if !defined(HACK_H) && !defined(WINTYPE_H)
    typedef union any {
        void *a_void;
        int a_int;
        char a_char;
    } anything;
    struct menu_item {
        anything item;      
        int count;          
    };
    typedef char CHAR_P;
    typedef char BOOLEAN_P;
    typedef char XCHAR_P;
    typedef union any ANY_P;
#endif

#if !defined(HACK_H)
    /**
     * @brief Opaque layout mapping to NetHack's core global 'u' structure.
     * @note Only fields required by the UI layer are exposed here. The internal 
     *       C memory layout must precisely match the engine's compilation.
     */
    typedef struct NHEPlayerState {
        int ux; /**< Player's current map X-coordinate */
        int uy; /**< Player's current map Y-coordinate */
        // Remaining internal fields are left hidden/opaque from the wrapper view
    } NHEPlayerState;

    #ifdef __cplusplus
    extern "C" {
    #endif

    /**
     * @brief Retrieves a direct pointer to NetHack's active global player state structure.
     * @return A pointer to the underlying player memory block.
     */
    NHEPlayerState * NHEGetPlayerState(void);

    #ifdef __cplusplus
    }
    #endif
#endif

/**
 * @protocol NetHackEngineDelegate
 * @brief Abstract interface defining the presentation and input commands required by the NetHack engine.
 *
 * Any long-lived orchestration class (typically MainViewController) must conform to this protocol
 * to catch low-level C events executing inside the engine background thread and route them safely 
 * onto the application's user interface.
 */
@protocol NetHackEngineDelegate <NSObject>

/**
 * @brief Requests the primary navigation controller instance from the parent app.
 * @return A pointer to the application's active UINavigationController context.
 */
- (UINavigationController *)navigationControllerContext;

- (void)callStartMenu:(winid)wid;

- (void)clearWindowWithId:(winid)wid;

/**
 * @brief Requests the viewport display bounds or scroll window to center around a target focal point.
 * @param x The horizontal map grid tile column coordinate.
 * @param y The vertical map grid tile row coordinate.
 */
- (void)clipAroundX:(int)x y:(int)y;

/**
 * @brief Requests the creation of a new window instance of a specific style archetype.
 * @param type The operational window type identifier (e.g., NHW_MAP, NHW_MENU, NHW_TEXT).
 * @return A unique \c winid integer tracking handle assigned to the generated window structure.
 */
- (winid)createWindow:(int)type;

/**
 * @brief Tears down a specific window tracking block and clears its associated memory allocation.
 * @param wid The target \c winid identifying handle of the window context to destroy.
 */
- (void)destroyWindow:(winid)wid;

/**
 * @brief Displays an external game asset file (like text logs, credits, or rumors) to the user.
 * @param filename The full or relative file target string path inside the resource bundles.
 * @param e        Set to YES if the file execution must validate structural existence before drawing.
 */
- (void)displayFile:(NSString *)filename mustExist:(BOOL)e;

/**
 * @brief Transitions a specific window layout into an active, visible display state.
 * @param wid      The target \c winid tracking code of the window layer to show.
 * @param blocking Set to YES if the calling thread loop must pause execution until user interaction yields.
 */
- (void)displayWindowId:(winid)wid blocking:(BOOL)blocking;

/**
 * @brief Displays a modal multiple-choice query prompt and blocks until a selection is made.
 * @param question The main C-string query text displayed to the player.
 * @param choices  A C-string listing acceptable shortcuts (e.g., "ynq"). If NULL, any key qualifies.
 * @param def      The fallback default character choice mapping to the Return key.
 * @return The character matching the option chosen by the user.
 */
- (char)displayYnQuestion:(const char *)question choices:(const char *)choices defaultChoice:(char)def;

/**
 * @brief Triggers the game launch role orchestration screen (choosing Race, Role, Gender, and Alignment).
 */
- (void)doPlayerSelection;

/**
 * @brief Renders a specific map tile or character sprite glyph onto a designated window grid.
 * @param wid   The window identifier handle.
 * @param x     The structural horizontal column grid coordinate.
 * @param y     The structural vertical row grid coordinate.
 * @param glyph The native core engine index tracker value matching a visual tile asset.
 */
- (void)drawGlyphToWindowWithId:(winid)wid atX:(int)x y:(int)y glyph:(int)glyph;

/**
 * @brief Signals that the internal structural menu creation phase has terminated for a window.
 * @param wid    The operational \c winid tracking identifier.
 * @param prompt Optional C-string title text or question prompt describing the menu choices.
 */
- (void)endMenuForWindowWithId:(int)wid prompt:(const char *)prompt;

/**
 * @brief Waits for the next user event and unpacks its primitives directly.
 * @param x Pointer where the horizontal grid column will be written.
 * @param y Pointer where the vertical grid row will be written.
 * @return The integer/ASCII value of the pressed key.
 */
- (int)fetchNextInputEventReturningX:(int *)x y:(int *)y;

/**
 * @brief Prompts the user for a raw textual input string (such as extended queries or renaming).
 * @param[out] line   Pointer array buffer where the resulting typed C-string will be copied.
 * @param[in]  prompt The context text showing the player what parameter string they are adjusting.
 */
- (void)getLine:(char *)line prompt:(const char *)prompt;

/**
 * @brief Processes a complex NetHack engine prompt lacking explicit choices (such as inventory item selections).
 * @param question The raw query text provided by the game engine.
 * @param def      The fallback default character action.
 * @return The final confirmation character response requested by the engine loop.
 */
- (char)handleComplexQueryPrompt:(const char *)question defaultChoice:(char)def;

/**
 * @brief Injects an unexpected asynchronous key character action token down into the engine loop.
 * @param ch The integer ASCII code or engine sequence command value mapping to the key trigger.
 */
- (void)postKeyEvent:(int)ch;

/**
 * @brief Clears volatile texture assets and local layout trackers mapped to font and map render pipelines.
 */
- (void)resetGlyphCache;

/**
 * @brief Displays a complex menu option sheet and blocks execution until choices finalize.
 * @param wid      The operational \c winid tracking identifier.
 * @param how      Selection filtering modifiers (e.g., PICK_NONE, PICK_ONE, PICK_ANY).
 * @param selected Double pointer destination tracking the array list addresses of chosen items.
 * @return The integer count tracking how many items were selected, or -1 if canceled.
 */
- (int)selectMenuForWindowWithId:(int)wid how:(int)how selectedItems:(struct menu_item **)selected;

/**
 * @brief Explicitly forces the virtual touchscreen keyboard viewport layer to show or hide.
 * @param d Set to YES to summon the standard keyboard focus layout, NO to retract it.
 */
- (void)showKeyboard:(BOOL)d;

/**
 * @brief Forces the view tier to execute immediate frame render evaluations on the main display threads.
 */
- (void)updateScreen;

- (void)writeStringToWindowWithId:(winid)wid attribute:(int)attr text:(const char *)text;

/**
 * @brief Forces a modal input wait loop capturing single-direction swipe or compass tile selections.
 * @return The direct movement key code token character matching the chosen vector.
 */
- (char)getDirectionInput;

/**
 * @brief Requests the application layer to find and delete the lock file name.
 * @param lockFileName The raw path/name string of the NetHack lock file.
 */
- (void)unlinkLockFile:(const char *)lockFileName;

/**
 * @brief Forces a modal selection interface capturing textual extended metadata instructions.
 * @return The operational command integer tracking token chosen by the player.
 */
- (int)getExtendedCommand;

/**
 * @brief Updates the numerical lifecycle phase tracker determining animated sprite cell steps.
 * @param frame The integer frame tracking counter sequence index.
 */
- (void)setAnimFrame:(int)frame;

/**
 * @brief Notifies the app container whether NetHack's primary main loop execution blocks are active.
 * @param inProgress Set to YES when entering moveloop pipelines, NO upon execution termination.
 */
- (void)setGameInProgress:(BOOL)inProgress;

/**
 * @brief Queries the operational lifecycle frame index tracking current animated cell assets.
 * @return The current frame integer offset sequence index.
 */
- (int)animFrame;

@end

/**
 * @class EngineWrapper36
 * @brief Main execution wrapper handling lifecycle events and launching the underlying C-state engine.
 */
@interface EngineWrapper36 : NSObject

/**
 * @brief Weak property link mapping down to the application coordinator processing UI and Input actions.
 */
@property (nonatomic, weak) id<NetHackEngineDelegate> delegate;

/**
 * @brief Public interface execution method enabling the application layer to pass its active
 *        navigation context down into the framework to initialize the character wizard.
 *
 * @param navController The application's active navigation coordinator layout frame.
 */
- (void)launchPlayerSelectionWizard:(UINavigationController *)navController;

/**
 * @brief Custom initialization routing providing upfront configuration parameters directly to NetHack's C-state environment.
 * 
 * Safely runs before any structural loops kick-off, eliminating global thread-race conditions.
 *
 * @param optionsString The raw sequential option adjustments mapping directly to \c NETHACKOPTIONS.
 * @param hackDirPath   The absolute target bundle resource directory path mapped to \c HACKDIR.
 *
 * @return Configured initialization wrapper instance reference.
 */
- (instancetype)initWithOptions:(NSString *)optionsString hackDir:(NSString *)hackDirPath;

/**
 * @brief Primary engine ignition method triggering NetHack's infinite main game loop loop.
 * @note This method executes blocking operations and must be dispatched onto an isolated thread context.
 */
- (void)frameworkMain;

/**
 * @brief Resets device-specific core-haptic engine patterns and tactile feedback wave files.
 */
- (void)hapticReset;

/**
 * @brief Public command letting the app trigger internal lock file cleanup.
 */
- (void)cleanUpLockFile;

/**
 * @brief Resets character selection parameters in a fall-through cascade based on selection type.
 * @param type The starting index parameter code to wipe (RESET_ROLE, RESET_RACE, etc.).
 */
- (void)resetPlayerChoices:(int)type;

- (NSString *)universalMoneyString;

/** @brief Evaluates whether the player is currently executing gameplay on a specialized Rogue layout dungeon level.
 * @return YES if the current level tracking matrices exist and match a Rogue archetype configuration grid.
 */
- (BOOL)isPlayerOnRogueLevel;

- (BOOL)isPlayerPosition:(int)x pos2:(int)y;

- (UIColor *)playerHealthColor;

- (BOOL)isPetGlyph:(int)glyph;

-(BOOL)isClickableTiles;

-(BOOL)isGameOver;
@end
