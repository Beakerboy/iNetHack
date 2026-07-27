#import "NH36EngineRunner.h"
#import <NetHackSharedUI/AbstractMainViewController.h>

// Declare the setup function exposed by your 3.6 winiphone.m
extern void iphone_set_ui_context(AbstractMainViewController *vc);

@implementation NH36EngineRunner

+ (UIViewController *)launchGameAndReturnViewController {
    // 1. Instantiate the 3.6 subclass (which inherits all shared layout code)
    // Note: If you are using standard storyboards/XIBs, ensure they point to the base class module
    MainViewController *gameVC = [[MainViewController alloc] init];
    
    // 2. Inject this concrete controller into winiphone.m's global pointer
    iphone_set_ui_context(gameVC);
    
    // 3. Trigger the background nethackThread loop inherited from MainViewController
    [gameVC launchNetHack];
    
    // 4. Return it so the Main App Target can push/present it on the screen
    #if __has_feature(objc_arc)
    return gameVC;
    #else
    return [gameVC autorelease];
    #endif
}

@end
