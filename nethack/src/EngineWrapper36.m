#import "nethack36/src/hack.h" 

@implementation EngineWrapper36
- (void)runEngine {
    moveloop(); // Because of the prefix header, this actually calls nh36_moveloop()
}
@end
