#import "TileSet.h"
#ifndef USE_TILES
#define USE_TILES
#endif
#import "hack.h"
extern short glyph2tile[];
@implementation TileSet

+ (int) glyphToTileIndex:(int)g {
	return glyph2tile[g];
}

@end
