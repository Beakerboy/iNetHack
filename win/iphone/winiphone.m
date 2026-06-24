#define kOptionWizard (@"wizard")
@interface WinIPhone : NSObject {}

+ (void) triggerInitialize;

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
                                @"`", kOptionBoulderSym,
                                @"YES", kOptionTravel,
                                @"YES", kOptionPickupThrown,
								@"YES", kOptionAutokick,
								@"YES", kOptionShowExp,
								@"YES", kOptionTime,
								@"YES", kOptionAutoDig,
								nil]];
}

@end

#if TARGET_IPHONE_SIMULATOR
    wizard = YES; //iNethack2 YES for sim usually..
#else */
    wizard = [defaults boolForKey:kOptionWizard];

#endif
