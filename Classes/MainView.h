//
//  MainView.h
//  iNetHack
//
//  Created by dirk on 6/26/09.
//  Copyright 2009 Dirk Zimmermann. All rights reserved.
//

//  This file is part of iNetHack.
//
//  iNetHack is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, version 2 of the License only.
//
//  iNetHack is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with iNetHack.  If not, see <http://www.gnu.org/licenses/>.

#import <UIKit/UIKit.h>

#define kKeyTileSize (@"tileSize")

@class AbstractMainViewController, TilePosition, Window, TileSet, ShortcutView;

@protocol MainViewDelegate <NSObject>
- (BOOL)mainViewShouldRenderRogueLevel;
@end

@interface MainView : UIView {

    AbstractMainViewController *mainViewController;
    UIFont *statusFont;
    CGSize maxTileSize;
    CGSize minTileSize;
    IBOutlet UITextField *dummyTextField;

    BOOL tiled;
    TileSet *tileSet;
    TileSet *tileSetAnim;
    TileSet *tileSets[3];
    
    CGPoint offset;
    ShortcutView *shortcutView;
    
    UIImage *petMark;
    
    CGSize tilesetTileSize;
    BOOL asciiTileset;
    BOOL ibmTileset;
    BOOL colorInvert; 
    BOOL animatedTileset;
    UIButton *moreButton;
    
    NSString *bundleVersionString;
    
    NSCache * cache; 
    NSCache * cache2; 
    
    id<MainViewDelegate> _delegate;
    AbstractMainViewController *mainViewController;
}

@property (nonatomic, assign) id<MainViewDelegate> delegate;
@property (nonatomic, assign) AbstractMainViewController *mainViewController;
@property (nonatomic, readonly) CGPoint start;
@property (nonatomic, readonly) CGSize tileSize;
@property (nonatomic, readonly) BOOL colorInvert;
@property (nonatomic, readonly) IBOutlet UITextField *dummyTextField;
@property (nonatomic, readonly, getter=isMoved) BOOL moved;
@property (nonatomic, readonly, retain) TileSet *tileSet;
@property (nonatomic, retain) Window *map;
@property (nonatomic, retain) Window *status;
@property (nonatomic, retain) Window *message;
@property (nonatomic, readonly) CGPoint subViewedCenter;
@property (nonatomic, readonly, retain) NSCache *cache; 
@property (nonatomic, readonly, retain) NSCache *cache2; 

- (void) drawTiledMap:(Window *)m clipRect:(CGRect)clipRect;
- (void) checkForRogueLevel;
- (UIFont *) fontAndSize:(CGSize *)size forStrings:(NSArray *)strings withFont:(UIFont *)font;
- (UIFont *) fontAndSize:(CGSize *)size forString:(NSString *)s withFont:(UIFont *)font;
- (TilePosition *) tilePositionFromPoint:(CGPoint)p;
- (void) moveAlongVector:(CGPoint)d;
- (void) resetOffset;
- (void) zoom:(CGFloat)d;
- (void) resetGlyphCache; 
@end

