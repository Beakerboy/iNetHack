#import "NH36MainViewController.h"

// Declare the external C main function from this target's winiphone.m
extern int iphone_main(int argc, char **argv);

@implementation NH36MainViewController

- (void) runNativeEngineLoop {
    // This runs safely on the background thread spawned by the parent class
    char *argv[] = {"nethack36"};
    iphone_main(1, argv);
}

@end
