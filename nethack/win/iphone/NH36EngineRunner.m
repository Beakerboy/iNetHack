#import <NetHackSharedUI/NHWindowPortDelegate.h>
#import <NetHackSharedUI/MainViewController.h>

// Declare the external C pointer from winiphone.m
extern id<NHWindowPortDelegate> g_window_delegate;
extern void iphone_set_ui_context(MainViewController *vc);
extern int iphone_main(int argc, char **argv);

@interface NH36EngineRunner : NSObject
+ (void)startEngineWithDelegate:(id<NHWindowPortDelegate>)delegate;
@end

@implementation NH36EngineRunner
+ (void)launchGameWithController:(MainViewController *)mainVC {
    iphone_set_ui_context(mainVC);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        char *argv[] = {"nethack"};
        iphone_main(1, argv);
    });
}
@end
