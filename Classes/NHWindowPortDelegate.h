
#import <Foundation/Foundation.h>

@protocol NHWindowPortDelegate <NSObject>
- (void)iphoneInitWindows;
- (void)iphonePutStr:(int)windowNum attribute:(int)attr text:(NSString *)text;
- (void)iphoneClearWindow:(int)windowNum;
- (void)iphoneDisplayWindow:(int)windowNum blocking:(BOOL)blocking;
// Add other standard NetHack window port functions mapped to Obj-C types
@end
