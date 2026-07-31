#import "TileSet.h"
#ifndef USE_TILES
#define USE_TILES
#endif
#import "hack.h"

@implementation AbstractTileSet

+ (int) glyphToTileIndex:(int)g {
	return glyph2tile[g];
}

@end
