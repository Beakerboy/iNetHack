//
//  AbstractMainViewController.h
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
#import "MainView.h"
#import "PlayerState.h"

#ifndef C
#define C(c)		(0x1f & (c))
#endif

#define kMinimumPinchDelta (15)
#define kMinimumPanDelta (20)
#define kCenterTapWidth (40)

@class Window, AbstractNethackMenuViewController, NethackYnFunction, TextInputViewController, NethackEventQueue;
@class DirectionInputViewController, ExtendedCommandViewController;
@class TouchInfo, TouchInfoStore;
@class TilePosition;
@class DMath;

@interface AbstractMainViewController : UIViewController <MainViewDelegate, UIActionSheetDelegate, UITextFieldDelegate> {
    
    IBOutlet AbstractNethackMenuViewController *nethackMenuViewController;
    IBOutlet TextInputViewController *textInputViewController;
    IBOutlet DirectionInputViewController *directionInputViewController;
    IBOutlet ExtendedCommandViewController *extendedCommandViewController;

    NSMutableDictionary *windows; 
    int windowIdCounter; 
    
    TilePosition *clip;
    NethackEventQueue *nethackEventQueue;
    NethackYnFunction *currentYnFunction;
    
    NSCondition *textInputCondition;
    NSCondition *uiCondition;
    
    CGRect tapRect;
    CGFloat initialDistance;
    TouchInfoStore *touchInfoStore;
    TilePosition *lastSingleTapDelta;
    DMath *dmath;
    
    BOOL gameInProgress;
    BOOL keyboardReturnShouldQueueEscape;
    int animFrame;
    
    NSTimeInterval doubleTapSensitivity;
    NSThread *nethackThread;
    Window *blockingMap;
}

@property (nonatomic, readonly, retain) PlayerState *playerState;
@property (nonatomic, assign) BOOL isRogueLevel;
@property (nonatomic, readonly, retain) NSDictionary *windows; 
@property (nonatomic, readonly, retain) TilePosition *clip;
@property (nonatomic, readonly) Window *mapWindow;
@property (nonatomic, readonly) Window *messageWindow;
@property (nonatomic, readonly) Window *statusWindow;
@property (nonatomic, retain) NethackEventQueue *nethackEventQueue;
@property (assign) BOOL gameInProgress;
@property (assign) int animFrame;
@property (nonatomic, readonly) int maxGlyphConstant;
@property (nonatomic, readonly) int noGlyphConstant;

// Shared Class Loggers (Safe because they use foundational NSString objects)
+ (void) message:(NSString *)format, ...;
+ (void) message:(NSString *)message format:(va_list)arg_list;

// Thread Management Execution Hooks
- (void) launchNetHack;
- (void) mainNethackLoop:(id)arg;
- (void) runNativeEngineLoop; // The overridable execution stub

// Window Management (Abstracted winid to int)
- (int) createWindow:(int)type;
- (void) destroyWindow:(int)wid;
- (Window *) windowWithId:(int)wid;
- (void) displayWindowId:(int)wid blocking:(BOOL)blocking;
- (void) displayMessage:(Window *)w;

// Core UI Engine Render Handlers
- (void) displayMenuWindow:(Window *)w;
- (void) displayMenuWindowOnUIThread:(Window *)w;
- (void) displayYnQuestion:(NethackYnFunction *)yn;
- (void) displayYnQuestionOnUIThread:(NethackYnFunction *)yn;
- (void) getLineOnUIThread:(NSString *)s;

// Synchronization Mechanics
- (void) waitForUser;
- (void) broadcastUIEvent;
- (void) broadcastCondition:(NSCondition *)condition;
- (void) waitForCondition:(NSCondition *)condition;

// Input Mapping 
- (char) getDirectionInput;
- (void) showDirectionInputView:(id)obj;
- (void) nethackKeyboard:(id)i;
- (int) getExtendedCommand;

// Rendering state & Assets Management
- (void) resetGlyphCache; 
- (void) doPlayerSelection;
- (void) nethackShowLog:(id)i;
- (void) displayFile:(NSString *)filename mustExist:(BOOL)e;
- (void) updateScreen;
- (void) showKeyboard:(BOOL)d;
- (void) didBecomeActive;

- (void)saveGameStateAndExit;
- (void)runNativeSaveCode;
- (void)handleApplicationTermination;
- (void)runNativeTerminateCode;
- (BOOL)isPetGlyph:(int)glyph;
- (void *)allocateEngineMenuListBuffer;
- (void)populateMenuList:(void *)menuList withAmount:(int)amount identifier:(const void *)identifier;
- (int)filterExtendedCommandsIntoNames:(NSMutableArray<NSString *> *)names 
                               indices:(NSMutableArray<NSNumber *> *)indices;
@end
