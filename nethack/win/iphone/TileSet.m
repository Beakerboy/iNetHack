#import "TileSet.h"

@implementation AbstractTileSet

+ (int) glyphToTileIndex:(int)g {
	return glyph2tile[g];
}

@end
