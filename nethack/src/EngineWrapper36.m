#import "hack.h"
#import "EngineWrapper36.h"

@implementation EngineWrapper36
- (void)runEngine {
    moveloop(); // Because of the prefix header, this actually calls nh36_moveloop()
}
@end
