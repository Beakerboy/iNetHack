#import <NetHackSharedUI/NHWindowPortDelegate.h>

// Declare the external C pointer from winiphone.m
extern id<NHWindowPortDelegate> g_window_delegate;
extern int nethack_main(int argc, char **argv); // Your C entry point

@interface NH36EngineRunner : NSObject
+ (void)startEngineWithDelegate:(id<NHWindowPortDelegate>)delegate;
@end

@implementation NH36EngineRunner
+ (void)startEngineWithDelegate:(id<NHWindowPortDelegate>)delegate {
    g_window_delegate = delegate;
    
    // Kick off the NetHack C engine loop (ideally on a background thread)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char *argv[] = {"nethack"};
        nethack_main(1, argv);
    });
}
@end
