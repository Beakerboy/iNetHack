#import "NH36AsciiTileSet.h"
#include "hack.h"
#include "display.h" // Safe: compiles directly alongside 3.6 engine source code

@implementation NH36AsciiTileSet

- (NSInteger)totalGlyphsCount {
    // Returns the exact NetHack 3.6 MAX_GLYPH calculation constant
    return MAX_GLYPH; 
}

@end
