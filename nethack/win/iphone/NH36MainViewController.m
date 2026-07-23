#import "NH36MainViewController.h"

// Declare the external C main function from this target's winiphone.m
extern int iphone_main(int argc, char **argv);
extern void save_currentstate(void);
extern int dosave(void);
extern char lock[]; 
@implementation NH36MainViewController

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
@end
