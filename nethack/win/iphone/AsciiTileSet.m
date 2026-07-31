#import "AsciiTileSet.h"
#include "hack.h"
#include "display.h" // Safe: compiles directly alongside 3.6 engine source code

@implementation AsciiTileSet

- (NSInteger)totalGlyphsCount {
    // Returns the exact NetHack 3.6 MAX_GLYPH calculation constant
    return MAX_GLYPH; 
}

- (CGImageRef) imageForGlyph:(int)g atX:(int)x y:(int)y {
	iflags.use_color = TRUE;
	int tile = [TileSet glyphToTileIndex:g];
    if (!images[tile]) {
        UIFont *font = [UIFont systemFontOfSize:28];
        int ochar, ocolor;
        unsigned special;
        mapglyph(g, &ochar, &ocolor, &special, x, y, 0);

        if (ibmTileset) {
            font = [UIFont fontWithName:@"Px437_IBM_VGA_8x16" size:64];
            //NSLog(@"glyph %d, spcl %d, tile %d %c", g, special, tile, ochar);
            int baseTile = tile;

            // Adjust for special wall tiles (see tile.c)
            if (tile >= 1038 && tile <= 1048) {
                //In_mines
                baseTile -= 187;
            } else if (tile >= 1049 && tile <= 1059) {
                //In_hell
                baseTile -= 198;
            } else if (tile >= 1060 && tile <= 1070) {
                //Is_knox
                baseTile -= 209;
            } else if (tile >= 1071 && tile <= 1081) {
                //In_sokoban
                baseTile -= 220;
            }
            if (Is_rogue_level(&u.uz)) {
                ochar = [self adjustTilesRogueLevel:baseTile withOchar:ochar withGlyph:g];
            } else {
                ochar = [self adjustTiles:baseTile withOchar:ochar];
            }
        }

        //NSLog(@"glyph %d, tile %d %C", g, tile, (unichar) ochar);

        NSString *s = [NSString stringWithFormat:@"%C", (unichar)ochar];
        CGSize size = [s sizeWithAttributes:@{NSFontAttributeName:font}];
        CGPoint p = CGPointMake((tileSize.width-size.width)/2, (tileSize.height-size.height)/2);
        if (ibmTileset) {
            UIGraphicsBeginImageContextWithOptions(tileSize, YES , 1);
        } else {
            UIGraphicsBeginImageContext(tileSize);
        }
        UIColor *color = [self mapNetHackColor:ocolor];
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        if (ibmTileset) {
            CGContextSetShouldAntialias(ctx, false);
            CGContextSetAllowsAntialiasing(ctx, 0);
        }
        if (Is_rogue_level(&u.uz) && !ibmTileset) {
            color = [UIColor lightGrayColor];
            if (ochar == '@') {
                color = [UIColor whiteColor];
            }
        }
        UIColor *bgColor = [UIColor blackColor];
        if (colorInvert) {
            bgColor = [UIColor whiteColor];
        }
        
        CGContextSetFillColorWithColor(ctx, bgColor.CGColor);
		CGRect r = CGRectZero;
		r.size = tileSize;
		CGContextFillRect(ctx, r);
		CGContextSetFillColorWithColor(ctx, color.CGColor);
        [s drawAtPoint:p withAttributes:@ { NSFontAttributeName: font, NSBackgroundColorAttributeName: [UIColor clearColor],
                NSForegroundColorAttributeName: color }];
		UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
		images[tile] = CGImageRetain(img.CGImage);
		UIGraphicsEndImageContext();
	}
	return images[tile];
}

- (BOOL)isGlyphObject:(int)glyph {
    return glyph_is_object(glyph);
}
@end
