// NetHackEngineProtocol.h
@protocol NetHackEngineProtocol <NSObject>
- (void)startGameWithSavePath:(NSString *)path;
- (void)sendInput:(NSString *)input;
// Add other lifecycle or UI callback hooks here
@end
