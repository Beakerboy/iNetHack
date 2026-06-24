#define kOptionWizard (@"wizard")

#if TARGET_IPHONE_SIMULATOR
    wizard = YES; //iNethack2 YES for sim usually..
#else */
    wizard = [defaults boolForKey:kOptionWizard];

#endif
