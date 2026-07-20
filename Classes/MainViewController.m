//
//  MainViewController.m
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

#import "iNethackAppDelegate.h"
#import "MainViewController.h"
#import "MainView.h"
#import "NethackMenuItem.h"
#import "Window.h"
#import "MenuViewController.h"
#import "MenuItem.h"
#import "NethackMenuViewController.h"
#import "NethackYnFunction.h"
#import "TextInputViewController.h"
#import "NethackEvent.h"
#import "NethackEventQueue.h"
#import "DirectionInputViewController.h"
#import "ExtendedCommandViewController.h"
#import "TextDisplayViewController.h"
#import "TilePosition.h"
#import "TouchInfo.h"
#import "TouchInfoStore.h"
#import "DMath.h"
#import "NSString+Regexp.h"
#import <NetHackEngine36/RoleSelectionController.h>
#define kOptionDoubleTapSensitivity (@"doubleTapSensitivity")
#define kConstThingsThatAreHereTitle (@"Things that are here:")
#define kConstThingsThatYouFeelHereTitle (@"Things that you feel here:")
#define kConstIntroductoryStoryTitle (@"It is written in the Book of")

static MainViewController *instance;

@interface MainViewController () <RoleSelectionControllerDelegate>

@end

@implementation MainViewController

@synthesize windows, clip, nethackEventQueue;
@synthesize gameInProgress, animFrame;

+ (instancetype)instance {
	return instance;
}

+ (void)messageWithoutFormat:(NSString*)msg {
	[[[self instance] messageWindow] putString:[msg cStringUsingEncoding:NSASCIIStringEncoding]];
}

+ (void) message:(NSString *)message format:(va_list)arg_list {
	NSString *msg = [[NSString alloc] initWithFormat:message arguments:arg_list];
	[self messageWithoutFormat:msg];
	[msg release];
}


+ (void) message:(NSString *)format, ... {
	va_list arg_list;
	va_start(arg_list, format);
	[self message:format format:arg_list];
	va_end(arg_list);
}

- (void) awakeFromNib {
	[super awakeFromNib];
	touchInfoStore = [[TouchInfoStore alloc] init];
	self.title = @"Dungeon";
	//windows = [[NSMutableArray alloc] init];
    windows = [[NSMutableDictionary alloc] init]; //iNethack2 making this a dict
    windowIdCounter=1;
	nethackEventQueue = [[NethackEventQueue alloc] init];
	uiCondition = [[NSCondition alloc] init];
	textInputCondition = [[NSCondition alloc] init];
	tapRect = CGRectMake(-25, -25, 50, 50);
	instance = self;
	lastSingleTapDelta = [[TilePosition alloc] init];
	clip = [[TilePosition alloc] init];
	dmath = [[DMath alloc] init];
    animFrame = 0;
	// read options
	doubleTapSensitivity = [[NSUserDefaults standardUserDefaults] floatForKey:kOptionDoubleTapSensitivity];
}

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	// the first time you rotate layoutSubivews doesn't get called :(
	// so make sure
	[self.view setNeedsLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:animated];
	[self.view becomeFirstResponder];
	[self.view setNeedsDisplay]; // seems necessary for shortcutview
}


- (void) launchNetHack {
	if (!nethackThread) {
		nethackThread = [[NSThread alloc] initWithTarget:self selector:@selector(mainNethackLoop:) object:nil];
		[nethackThread start];
	}
}

- (void) mainNethackLoop:(id)arg {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	EngineWrapper36 *wrapper = [[EngineWrapper36 alloc] init];
    [wrapper frameworkMain];
	[pool drain];
}

#pragma mark window properties

- (Window *) mapWindow {
	//for (Window *w in windows) {
    for (NSString* key in windows) {    //iNethack2 now a dict
        Window *w = [windows objectForKey:key];
        if (w.type == NHEW_MAP) {
			return w;
		}
	}
	return nil;
}

- (Window *) statusWindow {
//	for (Window *w in windows) {
    for (NSString* key in windows) {    //iNethack2 now a dict
        Window *w = [windows objectForKey:key];
        if (w.type == NHEW_STATUS) {
			return w;
		}
	}
	return nil;
}

- (Window *) messageWindow {
//	for (Window *w in windows) {
    for (NSString* key in windows) {    //iNethack2 now a dict
        Window *w = [windows objectForKey:key];
        if (w.type == NHEW_MESSAGE) {
			return w;
		}
	}
	return nil;
}

#pragma mark commands

- (void) nethackSearchCountEntered:(id)tf {
	NSString *s = ((UITextField *) tf).text;
	for (int i = 0; i < s.length; ++i) {
		char c = [s characterAtIndex:i];
		[nethackEventQueue addKeyEvent:c];
	}
	[nethackEventQueue addKeyEvent:'s'];
}

- (void) nethackSearch:(id)i {
	textInputViewController.target = self;
	textInputViewController.action = @selector(nethackSearchCountEntered:);
	textInputViewController.prompt = @"Enter search count";
	textInputViewController.text = @"20";
    self.navigationController.view.frame = [[UIScreen mainScreen] bounds]; //iNethack2 - fix for width on iphone6
	[self.navigationController pushViewController:textInputViewController animated:YES];
}

- (void) nethackKeyboard:(id)i {
	[self.navigationController popToRootViewControllerAnimated:NO];
	UITextField *tf = ((MainView *) self.view).dummyTextField;

    /* Disable word suggestions above onscreen keyboard */
    tf.autocorrectionType = UITextAutocorrectionTypeNo;
    tf.spellCheckingType = UITextSpellCheckingTypeNo;

	[tf becomeFirstResponder];
}

//iNethack2: call resetGlyphCache of MainView
- (void) resetGlyphCache {
    // ios15 prevent "[UIViewController view] must be used from main thread only" warning
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update UI in main thread.
            [(MainView *) self.view resetGlyphCache];
        });
    });
}

- (void) pushViewControllerOnMainThread:(UIViewController *)viewController
{
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void) displayText:(NSString *)text withCondition:(NSCondition *)condition isLog:(BOOL)l {
	TextDisplayViewController *viewController = [TextDisplayViewController new];
	viewController.log = l;
	viewController.text = text;
	viewController.condition = condition;
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self performSelectorOnMainThread:@selector(pushViewControllerOnMainThread:) withObject:viewController waitUntilDone:YES];
	[viewController release];
}

- (void) displayText:(NSString *)text withCondition:(NSCondition *)condition {
	[self displayText:text withCondition:condition isLog:NO];
}

- (void) nethackShowLog:(id)i {
	NSString *text = @"";
	for (NSString *l in self.messageWindow.log) {
		NSString *s = nil;
		if (text.length > 0) {
			s = [NSString stringWithFormat:@"\n%@", l];
		} else {
			s = l;
		}
		text = [NSString stringWithFormat:@"%@%@", text, s];
	}
	[self.messageWindow clearMessages];
	[self displayText:text withCondition:nil isLog:YES];
}

- (void) nethackShowLicense:(id)i {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"license" ofType:@""];
	NSString *text = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
	[self displayText:text withCondition:nil];
}

- (void) nethackShowHistory:(id)i {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"history" ofType:@""];
    NSString *text = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
    [self displayText:text withCondition:nil];
}

- (void) showManual:(id)obj {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"manual" ofType:@"html"];
	TextDisplayViewController *viewController = [TextDisplayViewController new];
	viewController.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	viewController.HTML = YES;
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}


- (void) showCredits:(id)obj {
	NSString *path = [[NSBundle mainBundle] pathForResource:@"credits" ofType:@"html"];
	TextDisplayViewController *viewController = [TextDisplayViewController new];
	viewController.text = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:NULL];
	viewController.HTML = YES;
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:viewController animated:YES];
	[viewController release];
}

- (void) hearseShowLog:(id)i {
	NSString *text = [NSString stringWithContentsOfFile:@"hearse.log" encoding:NSASCIIStringEncoding error:NULL];
	[self displayText:text withCondition:nil isLog:YES];
}

- (void) showMainMenu:(id)obj {
	NSMutableArray *menuItems = [NSMutableArray array];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Gear"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Wear Armor (W)" key:'W' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Take off (T)" key:'T' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Wield Weapon (w)" key:'w' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Switch Weapon (x)" key:'x' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Put on jewelry (P)" key:'P' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Remove jewelry (R)" key:'R' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Take off all armor (A)" key:'A' accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Actions"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Pickup (,)" key:',' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Open (o)" key:'o' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Close (c)" key:'c' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Kick (^d)" key:C('d') accessory:NO],
													  [MenuItem menuItemWithTitle:@"Teleport (^t)" key:C('t') accessory:NO],
													  [MenuItem menuItemWithTitle:@"Repeat (^a)" key:C('a') accessory:NO],
													  [MenuItem menuItemWithTitle:@"Eat (e)" key:'e' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Drop (d)" key:'d' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Drop Several (D)" key:'D' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Apply (a)" key:'a' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Quaff (q)" key:'q' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Engrave (E)" key:'E' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Ascend (<)" key:'<' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Descend (>)" key:'>' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Quiver (Q)" key:'Q' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Pay (p)" key:'p' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Rest (.)" key:'.' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Search (s)" target:self
																		 action:@selector(nethackSearch:)
																			  accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Magic"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"Read (r)" key:'r' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Zap (z)" key:'z' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Cast (Z)" key:'Z' accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Info"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"What's here (:)" key:':' accessory:NO],
													  [MenuItem menuItemWithTitle:@"What is (;)" key:';' accessory:NO],
													  [MenuItem menuItemWithTitle:@"Discoveries (\\)" key:'\\' accessory:YES],
													  [MenuItem menuItemWithTitle:@"Character Info (^x)" key:C('x') accessory:YES],
													  nil]]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Show Log" target:self
											action:@selector(nethackShowLog:) accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"License" target:self
											action:@selector(nethackShowLicense:) accessory:YES]];
    [menuItems addObject:[MenuItem menuItemWithTitle:@"History" target:self
                                              action:@selector(nethackShowHistory:) accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Manual" target:self
											action:@selector(showManual:) accessory:YES]];
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Credits" target:self
											action:@selector(showCredits:) accessory:YES]];
#ifdef WIZARD
	if (wizard) {
		[menuItems addObject:[MenuItem menuItemWithTitle:@"Wizard"
												children:[NSArray arrayWithObjects:
														  [MenuItem menuItemWithTitle:@"Detect Secrets"
																				  key:C('e') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Magic Mapping"
																				  key:C('f') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Create Monster"
																				  key:C('g') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Identify"
																				  key:C('i') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Special Levels"
																				  key:C('o') accessory:NO],
														  [MenuItem menuItemWithTitle:@"Intra-Level Teleport"
																				  key:C('t') accessory:YES],
														  [MenuItem menuItemWithTitle:@"Trans-Level Teleport"
																				  key:C('v') accessory:YES],
														  [MenuItem menuItemWithTitle:@"Wish"
																				  key:C('w') accessory:YES],
														  nil]]];
	}
#endif
	[menuItems addObject:[MenuItem menuItemWithTitle:@"Hearse"
											children:[NSArray arrayWithObjects:
													  [MenuItem menuItemWithTitle:@"View Log" target:self
																		   action:@selector(hearseShowLog:)
																		accessory:YES],
													  nil]]];
	MenuViewController* menuViewController = [MenuViewController new];
	menuViewController.menuItems = menuItems;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    
    [self.navigationController pushViewController:menuViewController animated:YES];
	[menuViewController release];
}

#pragma mark touch handling

- (char) directionFromTilePositionDelta:(TilePosition *)d {
	char direction = 0;
	if (d.x > 0 && d.y > 0) {
		// bottom right
		direction = 'n';
	} else if (d.x < 0 && d.y > 0) {
		// bottom left
		direction = 'b';
	} else if (d.x > 0 && d.y == 0) {
		// right
		direction = 'l';
	} else if (d.x < 0 && d.y == 0) {
		// left
		direction = 'h';
	} else if (d.x == 0 && d.y > 0) {
		// down
		direction = 'j';
	} else if (d.x == 0 && d.y < 0) {
		// up
		direction = 'k';
	} else if (d.x < 0 && d.y < 0) {
		// top left
		direction = 'y';
	} else if (d.x > 0 && d.y < 0) {
		// top right
		direction = 'u';
	}
	return direction;
}

// obsolete
- (char) directionFromDMathDirection:(dmathdirection)dmdir {
	char direction = 0;
	switch (dmdir) {
		case kUp:
			direction = 'k';
			break;
		case kUpRight:
			direction = 'u';
			break;
		case kRight:
			direction = 'l';
			break;
		case kDownRight:
			direction = 'n';
			break;
		case kDown:
			direction = 'j';
			break;
		case kDownLeft:
			direction = 'b';
			break;
		case kLeft:
			direction = 'h';
			break;
		case kUpLeft:
			direction = 'y';
			break;
	}
	return direction;
}

- (void) moveTilePosition:(TilePosition *)tp intoDMathDirection:(dmathdirection)dmdir {
	// dmdir is cartesian, tp is not ...
	switch (dmdir) {
		case kUp:
			tp.y--;
			break;
		case kUpRight:
			tp.x++;
			tp.y--;
			break;
		case kRight:
			tp.x++;
			break;
		case kDownRight:
			tp.x++;
			tp.y++;
			break;
		case kDown:
			tp.y++;
			break;
		case kDownLeft:
			tp.x--;
			tp.y++;
			break;
		case kLeft:
			tp.x--;
			break;
		case kUpLeft:
			tp.x--;
			tp.y--;
			break;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore storeTouches:touches];
	if (touches.count == 1) {
		UITouch *touch = [touches anyObject];
		if (touch.tapCount == 2) {
			TouchInfo *ti = [touchInfoStore touchInfoForTouch:touch];
			NSTimeInterval touchDuration = touch.timestamp - touchInfoStore.singleTapTimestamp;
			if (doubleTapSensitivity >= 1.0f || touchDuration < doubleTapSensitivity) {
				ti.doubleTap = YES;
			}
		} else {
			touchInfoStore.singleTapTimestamp = touch.timestamp;
		}
		//[self.view setNeedsDisplay];
	} else if (touches.count == 2) {
		NSArray *allTouches = [touches allObjects];
		UITouch *t1 = [allTouches objectAtIndex:0];
		UITouch *t2 = [allTouches objectAtIndex:1];
		CGPoint p1 = [t1 locationInView:self.view];
		CGPoint p2 = [t2 locationInView:self.view];
		CGPoint d = CGPointMake(p2.x-p1.x, p2.y-p1.y);
		initialDistance = sqrt(d.x*d.x + d.y*d.y);
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if (touchInfoStore.count == touches.count) {
		if (touches.count == 1) {
			UITouch *touch = [touches anyObject];
			TouchInfo *ti = [touchInfoStore touchInfoForTouch:[touches anyObject]];
			if (!ti.pinched) {
				CGPoint p = [touch locationInView:self.view];
				CGPoint delta = CGPointMake(p.x-ti.currentLocation.x, p.y-ti.currentLocation.y);
				BOOL move = NO;
                if (!ti.moved && (fabs(delta.x)+fabs(delta.y) > kMinimumPanDelta)) {
					ti.moved = YES;
					move = YES;
				} else if (ti.moved) {
					move = YES;
				}
				if (move) {
					[(MainView *) self.view moveAlongVector:delta];
					ti.currentLocation = p;
					[self.view setNeedsDisplay];
				}
			}
		} else if (touches.count == 2) {
			for (UITouch *t in touches) {
				TouchInfo *ti = [touchInfoStore touchInfoForTouch:t];
				ti.pinched = YES;
			}
			NSArray *allTouches = [touches allObjects];
			UITouch *t1 = [allTouches objectAtIndex:0];
			UITouch *t2 = [allTouches objectAtIndex:1];
			CGPoint p1 = [t1 locationInView:self.view];
			CGPoint p2 = [t2 locationInView:self.view];
			CGPoint d = CGPointMake(p2.x-p1.x, p2.y-p1.y);
			CGFloat currentDistance = sqrt(d.x*d.x + d.y*d.y);
			if (initialDistance == 0) {
				initialDistance = currentDistance;
			} else if (currentDistance-initialDistance > kMinimumPinchDelta) {
				// zoom (in)
				CGFloat zoom = currentDistance-initialDistance;
				[(MainView *) self.view zoom:zoom];
				initialDistance = currentDistance;
			} else if (initialDistance-currentDistance > kMinimumPinchDelta) {
				// zoom (out)
				CGFloat zoom = currentDistance-initialDistance;
				[(MainView *) self.view zoom:zoom];
				initialDistance = currentDistance;
			}
		}
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[touchInfoStore removeTouches:touches];
}

/**
 * @brief Handles the conclusion of touch interactions on the primary interface.
 *
 * @details Evaluates touch states to differentiate between single taps, double taps, 
 *          and complex multi-touch gestures (like pinches or drags). Based on the gesture 
 *          type and active gameplay state, it maps screen coordinate hits into 
 *          NetHack core context actions (such as direct coordinate target inputs, 
 *          center-tile selections, direction-based movement, or macro repeats).
 *
 * @param touches A set of UITouch objects representing the ending phase of the interaction.
 * @param event   An object encapsulating the specific touch event characteristics.
 * 
 * @note Triggers internal offset resets on the MainView wrapper and updates global queue parameters.
 * @see touchInfoStore
 * @see nethackEventQueue
 */
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (touches.count == 1) {
        TouchInfo *ti = [touchInfoStore touchInfoForTouch:[touches anyObject]];
        
        if (!ti.pinched && !ti.moved) {
            if (!ti.doubleTap) {
                [self handleSingleTap:[touches anyObject]];
            } else {
                [self handleDoubleTap];
            }
        }
    }
    initialDistance = 0;
    [touchInfoStore removeTouches:touches];
}

/**
 * @brief Processes valid single-tap interactions to clear overlays or trigger movement.
 */
- (void)handleSingleTap:(UITouch *)touch {
    if (blockingMap) {
        blockingMap.blocking = NO;
        blockingMap = nil;
        [(MainView *)self.view resetOffset];
        [self broadcastUIEvent];
        return;
    }

    CGPoint p = [touch locationInView:self.view];
    TilePosition *tp = [(MainView *)self.view tilePositionFromPoint:p];
    NethackEvent *lastEvent = nethackEventQueue.lastEvent;
    iNethackAppDelegate *appDelegate = (iNethackAppDelegate *)[UIApplication sharedApplication].delegate;
    
    if ([(MainView *)self.view isMoved] || lastEvent.key == ';' || [appDelegate.nethackEngine isClickableTiles]) {
        [self queueTargetedEventAtX:tp.x y:tp.y];
    } else {
        [self handleDirectionalOrCenterTapAtPoint:p];
    }
}

/**
 * @brief Differentiates between a center-screen player tap and a directional travel vector.
 */
- (void)handleDirectionalOrCenterTapAtPoint:(CGPoint)p {
    NHEPlayerState *player = NHEGetPlayerState();
    CGPoint viewCenter = [(MainView *)self.view subViewedCenter];
    CGRect middleSquare = CGRectMake(viewCenter.x - kCenterTapWidth / 2,
                                     viewCenter.y - kCenterTapWidth / 2,
                                     kCenterTapWidth, kCenterTapWidth);
    
    if (CGRectContainsPoint(middleSquare, p)) {
        // Tap on player (center) tile
        [self queueTargetedEventAtX:player->ux y:player->uy];
    } else {
        // Direction-based movement
        CGPoint pointDelta = CGPointMake(p.x - viewCenter.x, p.y - viewCenter.y);
        pointDelta.y *= -1; // Flip UIKit coordinate system to match grid space
        pointDelta = [DMath normalizedPoint:pointDelta];
        dmathdirection dmdir = [dmath directionFromVector:pointDelta];
        
        TilePosition *tp = [TilePosition tilePositionWithX:player->ux y:player->uy];
        [self moveTilePosition:tp intoDMathDirection:dmdir];
        [self queueTargetedEventAtX:tp.x y:tp.y];
    }
}

/**
 * @brief Dispatches the final NetHack coordinate event block to the queue.
 */
- (void)queueTargetedEventAtX:(int)x y:(int)y {
    NHEPlayerState *player = NHEGetPlayerState();
    lastSingleTapDelta.x = x - player->ux;
    lastSingleTapDelta.y = y - player->uy;
    
    NethackEvent *e = [[NethackEvent alloc] init];
    e.x = x;
    e.y = y;
    e.key = 0;
    [nethackEventQueue addNethackEvent:e];
    [e release];
    
    [(MainView *)self.view resetOffset];
}

/**
 * @brief Processes valid double-tap gestures to issue travel ('g') macros.
 */
- (void)handleDoubleTap {
    TilePosition *delta = lastSingleTapDelta;
    // Check if the previous tap was exactly 1 tile away radially or orthogonally
    if (((abs(delta.x) == 0 || abs(delta.x) == 1) && (abs(delta.y) == 0)) || abs(delta.y) == 1) {
        char direction = [self directionFromTilePositionDelta:delta];
        if (direction) {
            [nethackEventQueue addKeyEvent:'g']; // NetHack travel command prefix
            [nethackEventQueue addKeyEvent:direction];
        }
    }
}

#pragma mark windowing

- (winid) createWindow:(int)type {
	Window *w = [[Window alloc] initWithType:type];
    [windows setValue:w forKey:[NSString stringWithFormat:@"%d", windowIdCounter]];
    windowIdCounter++;
	[w release];
    return (winid) (windowIdCounter-1);
}

- (void) destroyWindow:(winid)wid {
    [windows removeObjectForKey:[NSString stringWithFormat:@"%d",wid]];
}

- (Window *) windowWithId:(winid)wid {
    return [windows objectForKey:[NSString stringWithFormat:@"%d",wid]]; //iNethack2
}

- (void) displayWindowId:(winid)wid blocking:(BOOL)blocking {
	BOOL mapBlocked = NO;
	Window *w = [self windowWithId:wid];
	switch (w.type) {
		case NHEW_MENU:
		case NHEW_TEXT:
			if (w.strings.count > 0) {
				[uiCondition lock];
				[self performSelectorOnMainThread:@selector(displayMessage:) withObject:w waitUntilDone:YES];
				[uiCondition wait];
				[uiCondition unlock];
			}
			break;
		case NHEW_MAP:
			if (blocking) {
				w.blocking = YES;
				blockingMap = w;
				mapBlocked = YES;
			}
		case NHEW_MESSAGE:
            // ios15 prevent "[UIViewController view] must be used from main thread only" warning
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    // Update UI in main thread.
                    [self.view performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
                });
            });
            
			if (mapBlocked) {
				[self waitForUser];
			}
			break;
		default:
			break;
	}
}

- (void) displayMessage:(Window *)w {
    [w lock];
    NSString *message = [w.text copy];
    [w clearMessages];
    [w unlock];
    
    if ([message containsString:kConstThingsThatAreHereTitle] || [message containsString:kConstThingsThatYouFeelHereTitle]) {
        NSRange r = [message rangeOfString:@"\n"];
        NSString *title = [message substringToIndex:r.location];
        NSString *toReplaced = [NSString stringWithFormat:@"%@\n", title];
        NSString *text = [message stringByReplacingOccurrencesOfString:toReplaced withString:@""];
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                                 message:text
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK"
                                                           style:UIAlertActionStyleCancel
                                                         handler: ^(UIAlertAction *action) { [self broadcastUIEvent]; }];
        UIAlertAction *pickupAction = [UIAlertAction actionWithTitle:@"Pickup"
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction *action) {
            [nethackEventQueue addKeyEvent:','];
            [self broadcastUIEvent];
        }];
        [alertController addAction:okAction];
        [alertController addAction:pickupAction];
        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        if (![UIAlertController class]) {
            UIAlertView *alert2 = [[UIAlertView alloc] initWithTitle:@"Message" message:message delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert2 show];
            return;
        } else {
            // Use monospace font if showing game ending info, the introductory text, or in wizard mode.
			iNethackAppDelegate *appDelegate = (iNethackAppDelegate *)[UIApplication sharedApplication].delegate;
			NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	        BOOL wizard = [defaults boolForKey:@"wizard"];
            if ([appDelegate.nethackEngine isGameOver] || wizard || [message containsString:kConstIntroductoryStoryTitle]) {
                if ([message containsString:kConstIntroductoryStoryTitle]) {
                    // Format the intro text a bit better for narrow displays.
                    message = [self formatMessageForWideScreen:message];
                }
                [self showMonospacedMessageInModalWithOK:message];
                return;
            }
            UIAlertController *alert2 = [UIAlertController alertControllerWithTitle:@"Message"
                                                                            message:nil // Initial message is nil
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            alert2.message = message;
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK"
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action) {
                [self broadcastUIEvent];
            }];
            
            [alert2 addAction:ok];
            [self presentViewController:alert2 animated:YES completion:nil];
            return;
        }
    }
}

- (void)drawGlyphToWindowWithId:(winid)wid atX:(int)x y:(int)y glyph:(int)glyph {
    // Look up the window from your private tracking dictionary
    Window *w = [windows objectForKey:@(wid)];
    
    // Map directly to your working application method interface
    [w setGlyph:glyph atX:x y:y];
}

- (NSString *)formatMessageForWideScreen:(NSString *)message {
    NSMutableString *formattedMessage = [NSMutableString stringWithString:message];

    // Replace single line breaks with spaces, but keep double line breaks.
    NSRange range = [formattedMessage rangeOfString:@"\n"];
    while (range.location != NSNotFound) {
        if (range.location + 1 < formattedMessage.length &&
            [formattedMessage characterAtIndex:range.location + 1] == '\n') {
            // Double line break.
            range = [formattedMessage rangeOfString:@"\n" options:0 range:NSMakeRange(range.location + 2, formattedMessage.length - (range.location + 2))];
        } else {
            // Single line break, turn into space.
            [formattedMessage replaceCharactersInRange:range withString:@" "];
            range = [formattedMessage rangeOfString:@"\n" options:0 range:NSMakeRange(range.location + 1, formattedMessage.length - (range.location + 1))];
        }
    }

    // Remove multiple spaces and replace with single space.
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@" +" options:0 error:nil];
    [regex replaceMatchesInString:formattedMessage options:0 range:NSMakeRange(0, formattedMessage.length) withTemplate:@" "];

    return formattedMessage;
}

- (void)showMonospacedMessageInModalWithOK:(NSString *)message {
    UIViewController *modalVC = [[UIViewController alloc] init];
    modalVC.view.backgroundColor = [UIColor whiteColor];

    UITextView *textView = [[UITextView alloc] init];
    textView.text = message;
    if (@available(iOS 13.0, *)) {
        textView.font = [UIFont monospacedSystemFontOfSize:12 weight:UIFontWeightRegular];
    } else {
        textView.font = [UIFont fontWithName:@"Courier" size:12];
    }

    textView.editable = NO;
    textView.translatesAutoresizingMaskIntoConstraints = NO;
    [modalVC.view addSubview:textView];

    // OK button
    UIButton *okButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [okButton setTitle:@"OK" forState:UIControlStateNormal];
    okButton.translatesAutoresizingMaskIntoConstraints = NO;
    [okButton addTarget:self action:@selector(dismissModal:) forControlEvents:UIControlEventTouchUpInside];
    [modalVC.view addSubview:okButton];

    // Auto Layout constraints
    UILayoutGuide *safeArea = modalVC.view.safeAreaLayoutGuide;

    // Text View Constraints (using safe area)
    [textView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor constant:10].active = YES;
    [textView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor constant:-10].active = YES;
    [textView.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:20].active = YES;
    [textView.bottomAnchor constraintEqualToAnchor:okButton.topAnchor constant:-20].active = YES;

    // OK Button Constraints (using safe area)
    [okButton.centerXAnchor constraintEqualToAnchor:safeArea.centerXAnchor].active = YES;
    [okButton.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor constant:-20].active = YES;
    [okButton.widthAnchor constraintEqualToConstant:100].active = YES;
    [okButton.heightAnchor constraintEqualToConstant:40].active = YES;

    // Calculate text width for horizontal scrolling
    CGSize textSize = [message boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, modalVC.view.bounds.size.height - 100)
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{NSFontAttributeName: textView.font}
                                         context:nil].size;

    // Constrain TextView Width (with priority)
    NSLayoutConstraint *widthConstraint = [textView.widthAnchor constraintEqualToConstant:textSize.width + 20];
    widthConstraint.priority = UILayoutPriorityDefaultLow;
    widthConstraint.active = YES;

    // Set content hugging priority
    [textView setContentHuggingPriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

    // Present the modal
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:modalVC];
       navController.modalPresentationStyle = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? UIModalPresentationPopover : UIModalPresentationFormSheet;

    navController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    if (@available(iOS 13.0, *)) {
        navController.modalInPresentation = YES; //disallow swipe down to dismiss window
    }
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && navController.modalPresentationStyle == UIModalPresentationPopover) {
        // Configure popover presentation on iPad
        navController.popoverPresentationController.sourceView = self.view;
        navController.popoverPresentationController.sourceRect = self.view.bounds;
        navController.popoverPresentationController.permittedArrowDirections = 0;

        // Adjust preferred content size
        CGFloat width = self.view.bounds.size.width * 0.75;
        CGFloat height = self.view.bounds.size.height * 0.75;
        navController.preferredContentSize = CGSizeMake(width, height);
    }
    
    
    [self presentViewController:navController animated:YES completion:nil];

}

- (void)dismissModal:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
    [self broadcastUIEvent];
}

- (void) displayMenuWindow:(Window *)w {
	[uiCondition lock];
	[self performSelectorOnMainThread:@selector(displayMenuWindowOnUIThread:) withObject:w waitUntilDone:YES];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void) displayMenuWindowOnUIThread:(Window *)w {
	nethackMenuViewController.menuWindow = w;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:nethackMenuViewController animated:YES];
}

//iNethack2 -- trying this function instead of clickedButtonAtIndex as clickedButtonAtIndex was occasionally hanging
-(void)alertView:(UIAlertView *)alertView willDismissWithButtonIndex:(NSInteger)buttonIndex {
    //NSLog(@"alert finished");
    if (alertView.numberOfButtons == 2) {
        if (buttonIndex == 1) {
            [nethackEventQueue addKeyEvent:','];
        }
    }
    [alertView release];
    [self broadcastUIEvent];
}

//iNethack2 -- trying this function instead of clickedButtonAtIndex as clickedButtonAtIndex was occasionally hanging
- (void)actionSheet:(UIActionSheet *)actionSheet willDismissWithButtonIndex:(NSInteger)buttonIndex {
    currentYnFunction.chosen = (int) buttonIndex;
    [self broadcastUIEvent];
    [actionSheet release];
    currentYnFunction = nil;
}

- (void) displayYnQuestion:(NethackYnFunction *)yn {
	[uiCondition lock];
	[self performSelectorOnMainThread:@selector(displayYnQuestionOnUIThread:) withObject:yn waitUntilDone:YES];
	[uiCondition wait];
	[uiCondition unlock];
}

//iNethack2: screenSize that works with both iOS7 + 8
+ (CGSize)screenSize {
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    //Check for insets in case we need to adjust safe screen size
    BOOL hasInsets = NO;
    if (@available(iOS 11.0, *)) {
        if ([[[[UIApplication sharedApplication] delegate] window] safeAreaInsets].top > 0.0) {
            hasInsets = YES;
        }
        if (hasInsets) {
            UIEdgeInsets safeRect = [[[[UIApplication sharedApplication] delegate] window] safeAreaInsets];
            screenSize.height-=safeRect.top;
            screenSize.height-=safeRect.bottom;
            screenSize.width-=safeRect.left;
            screenSize.width-=safeRect.right;
        }
    }

    if ((NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_7_1) && UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        return CGSizeMake(screenSize.height, screenSize.width);
    }
    return screenSize;
}

- (void) getLine:(char *)line prompt:(const char *)p {
	NSString *s = [NSString stringWithCString:p encoding:NSASCIIStringEncoding];
	[self performSelectorOnMainThread:@selector(getLineOnUIThread:) withObject:s waitUntilDone:YES];
	[self waitForCondition:textInputCondition];
	s = textInputViewController.text;
	[s getCString:line maxLength:NHE_BUFSZ encoding:NSASCIIStringEncoding];
}

- (void) getLineOnUIThread:(NSString *)s {
	textInputCondition = [[NSCondition alloc] init];
	textInputViewController.condition = textInputCondition;
	textInputViewController.prompt = s;
	textInputViewController.text = @"Elbereth";
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] applicationFrame]; //iNethack2 - fix for width on iphone6
	[self.navigationController pushViewController:textInputViewController animated:YES];
}

- (char) getDirectionInput {
	[self performSelectorOnMainThread:@selector(showDirectionInputView:) withObject:nil waitUntilDone:YES];
	[self waitForCondition:uiCondition];
    // ios15 use gcd to remove this view to prevent crash.
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update UI in main thread.
            [directionInputViewController.view removeFromSuperview];
        });
    });
	return directionInputViewController.direction;
}

- (void) showDirectionInputView:(id)obj {
    // iNethack2: iOS9: Keyboard stopped dismissing when yn menu appears, the next line forced it to close
    [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
    [self.view addSubview:directionInputViewController.view];
	directionInputViewController.view.frame = self.view.frame;
}

- (void) showExtendedCommandMenu:(id)obj {
	extendedCommandViewController.title = @"Extended Command";
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationController.view.frame = [[UIScreen mainScreen] bounds]; //iNethack2 - fix for width on iphone6
    [self.navigationController pushViewController:extendedCommandViewController animated:YES];
}

- (int) getExtendedCommand {
	[self performSelectorOnMainThread:@selector(showExtendedCommandMenu:) withObject:nil waitUntilDone:YES];
	[self waitForCondition:uiCondition];
	return extendedCommandViewController.result;
}

- (void)didCompleteRoleSelection:(id)sender {
	NSAssert(flags.initalign != -1, @"Alignment was not set");
	NSAssert(flags.initrace  != -1, @"Race was not set");
	NSAssert(flags.initgend  != -1, @"Gender was not set");
	NSAssert(flags.initrole  != -1, @"Role was not set");
	[self broadcastUIEvent];
}

/**
 * @brief Coordinates the player role selection wizard by handing off the application's 
 *        navigation context to the framework layer and suspending the engine thread.
 *
 * This method is invoked by the core engine thread via the delegate boundary during game initialization. 
 * It offloads the rendering and management of character generation screens to the framework, 
 * passing along the active \c UINavigationController. 
 *
 * @note This method blocks the calling engine background thread using a condition loop (\c uiCondition)
 *       to prevent NetHack's primary initialization sequence from advancing prematurely while 
 *       the user is interacting with the modal selection menus on the main UI thread.
 *
 * @see EngineWrapper36
 * @see waitForCondition:
 */
- (void)doPlayerSelection {
    iNethackAppDelegate *appDelegate = (iNethackAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.nethackEngine launchPlayerSelectionWizard:self.navigationController];
    [self waitForCondition:uiCondition];
}

- (void) displayFile:(NSString *)filename mustExist:(BOOL)e {
	if (![filename isEqualToString:@"news"]) {
		NSString *path = [[NSBundle mainBundle] pathForResource:filename ofType:@""];
		if (path) {
			NSCondition *textDisplayCondition = [[NSCondition alloc] init];
			NSString *t = [NSString stringWithContentsOfFile:path encoding:NSASCIIStringEncoding error:NULL];
			[self displayText:t withCondition:textDisplayCondition];
			[self waitForCondition:textDisplayCondition];
			[textDisplayCondition release];
		} else {
			if (e) {
				NSLog(@"error: could not find file %@ for display", filename);
			}
		}
	}
}

- (void) updateScreen {
    // ios15 prevent "[UIViewController view] must be used from main thread only" warning
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            // Update UI in main thread.
            [self.view performSelectorOnMainThread:@selector(setNeedsDisplay) withObject:nil waitUntilDone:YES];
        });
    });

}

- (void) showKeyboard:(BOOL)d {
	if (d) {
		keyboardReturnShouldQueueEscape = YES;
		[self performSelectorOnMainThread:@selector(nethackKeyboard:) withObject:nil waitUntilDone:YES];
	} else {
		// todo find a save way to let keyboard disappear
		keyboardReturnShouldQueueEscape = NO;
	}
}

- (void) didBecomeActive {
    iNethackAppDelegate *appDelegate = (iNethackAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.nethackEngine hapticReset];
}


#pragma mark condition utilities

- (void) waitForUser {
	[uiCondition lock];
	[uiCondition wait];
	[uiCondition unlock];
}

- (void) broadcastUIEvent {
	[self broadcastCondition:uiCondition];
}

- (void) broadcastCondition:(NSCondition *)condition {
	[condition lock];
	[condition broadcast];
	[condition unlock];
}

- (void) waitForCondition:(NSCondition *)condition {
	[condition lock];
	[condition wait];
	[condition unlock];
}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (keyboardReturnShouldQueueEscape) {
		[nethackEventQueue addKeyEvent:27];
	}
	[textField resignFirstResponder];
	return YES;
}

-  (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	for (int i = 0; i < string.length; ++i) {
		[nethackEventQueue addKeyEvent:[string characterAtIndex:i]];
	}
	[self broadcastUIEvent];
	return YES;
}

#pragma mark UINavigationControllerDelegate

/*
- (void)navigationController:(UINavigationController *)navigationController
	   didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	NSLog(@"did show %@", viewController);
}
 */

#pragma mark dealloc

- (void)dealloc {
	[touchInfoStore release];
	[uiCondition release];
	[textInputCondition release];
	[windows release];
	[lastSingleTapDelta release];
	[clip release];
	[dmath release];
    [super dealloc];
}

#pragma mark - NetHackEngineDelegate Methods

- (void)addItemToMenuWindowWithId:(winid)wid
                            glyph:(int)glyph
                       identifier:(const ANY_P *)identifier
                      accelerator:(CHAR_P)accelerator
                       groupAccel:(CHAR_P)group_accel
                        attribute:(int)attr
                            title:(const char *)str
                     preselected:(BOOLEAN_P)presel {
    // Instantiate your menu item completely inside the app target layout
    NethackMenuItem *i = [[NethackMenuItem alloc] initWithId:identifier 
                                                       title:str 
                                                       glyph:glyph 
                                                 preselected:presel ? YES : NO 
                                                 accelerator:accelerator];
    
    // Fetch the target window from your private application dictionary
    Window *w = [windows objectForKey:@(wid)];
    
    // Append the configuration entry
    [w addMenuItem:i];
    
    // Release memory under your working project rules
    [i release];
}

- (void)callStartMenu:(winid)wid {
    Window *w = [windows objectForKey:@(wid)];
    [w startMenu];
}

- (void)clearWindowWithId:(winid)wid {
    Window *w = [self windowWithId:wid];
	[w clear];
}

/**
 * @brief Adjusts the internal map clipping position and anchors the display viewport layout.
 *
 * Fulfills the \c NetHackEngineDelegate protocol requirements. This method receives tracking 
 * signals from the underlying framework layer and applies them directly to the local \c clip 
 * structure, shielding the framework from direct awareness of your custom positioning layout.
 *
 * @param x The raw horizontal integer grid coordinate passed from the engine loop.
 * @param y The raw vertical integer grid coordinate passed from the engine loop.
 *
 * @note This method executes safely on the calling thread, but any downstream view adjustments 
 *       or animated scroll updates should be pushed to the main thread.
 */
- (void)clipAroundX:(int)x y:(int)y {
    self.clip.x = x;
    self.clip.y = y;
}

- (char)displayYnQuestion:(const char *)question choices:(const char *)choices defaultChoice:(char)def {
    // Safely convert your raw C primitives into Objective-C strings
    NSString *questionStr = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
    NSString *choicesStr = choices ? [NSString stringWithCString:choices encoding:NSASCIIStringEncoding] : nil;
    
    // Instantiate your tracking model completely inside the App layer
    NethackYnFunction *yn = [[NethackYnFunction alloc] initWithQuestion:questionStr 
                                                                choices:choicesStr 
                                                          defaultChoice:def];
    
    // Trigger your existing visual prompt logic (which blocks the background loop)
    [self displayYnQuestion:yn];
    
    // Extract the user's primitive outcome choice character
    char finalChoice = yn.choice;
    
    // Clean up your allocation memory safely under standard ARC/MRC rules
    [yn release]; // or let ARC handle it if you removed manual reference counting
    
    return finalChoice;
}

- (int)fetchNextInputEventReturningX:(int *)x y:(int *)y {
    // 1. Block and fetch the event object inside the app layer
    NethackEvent *e = [nethackEventQueue waitForNextEvent];
    
    // 2. Unpack the object properties directly into the engine's pointers
    if (e) {
        if (x) *x = e.x;
        if (y) *y = e.y;
        return e.key;
    }
    
    return 027; // Fallback safety escape
}

- (char)handleComplexQueryPrompt:(const char *)question defaultChoice:(char)def {
    NSString *s = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
    
    // 1. Handle Direction inputs
    if ([s containsString:@"direction"]) {
        return [self getDirectionInput];
    }
    
    NSString *q = [NSString stringWithCString:question encoding:NSASCIIStringEncoding];
    NSString *preLets = [q substringBetweenDelimiters:@"[]"];
    
    // 2. Handle Structured Inventory Queries
    if (preLets && preLets.length > 0) {
        // Fetch the window via your local application dictionary safely
        Window *inventoryWindow = [windows objectForKey:@(NHE_WIN_INVEN)];
        inventoryWindow.nethackMenuItem = nil;
        
        BOOL alphaBegan = NO;
        BOOL terminateLoop = NO;
        int index = 0;
        int start = 0; 
        
        for (int i = 0; i < preLets.length && !terminateLoop; ++i) {
            index = i;
            char c = [preLets characterAtIndex:i];
            if (!alphaBegan) {
                switch (c) {
                    case '$': inventoryWindow.acceptMoney = YES; break;
                    case '-': inventoryWindow.acceptBareHanded = YES; break;
                    default:
                        if (isalpha(c)) {
                            start = i;
                            alphaBegan = YES;
                        }
                        break;
                }
            } else {
                if (c == ' ') { terminateLoop = YES; }
            }
        }
        if (!terminateLoop) { index++; }
        
        NSRange r = NSMakeRange(start, index - start);
        NSString *lets = [preLets substringWithRange:r];
        
        r = [preLets rangeOfString:@"or "];
        if (r.location == NSNotFound) {
            r = [preLets rangeOfString:@"*"]; 
        }
        if (r.location != NSNotFound) {
            NSString *moreOptions = [preLets substringFromIndex:r.location + r.length];
            if ([preLets isEqual:@"*"]) { moreOptions = preLets; }
            for (int i = 0; i < moreOptions.length; ++i) {
                char c = [moreOptions characterAtIndex:i];
                if (c == '*') { inventoryWindow.acceptMore = YES; }
            }
        }
        
        lets = [self expandInventoryLetters:lets];
        inventoryWindow.menuPrompt = q;
        
        // Execute your local application inventory presentation layout
        char c = display_inventory([lets cStringUsingEncoding:NSASCIIStringEncoding], TRUE);
        
        inventoryWindow.acceptMoney      = NO;
        inventoryWindow.acceptBareHanded = NO;
        inventoryWindow.acceptMore       = NO;
        
        // Extract multi-item stack quantities if applicable
        if (inventoryWindow.nethackMenuItem && inventoryWindow.nethackMenuItem.amount != -1) {
            int amount = inventoryWindow.nethackMenuItem.amount;
            inventoryWindow.nethackMenuItem = nil;
            
            NSString *stringAmount = [NSString stringWithFormat:@"%d%c", amount, c];
            char firstChar = [stringAmount characterAtIndex:0];
            
            for (int i = 1; i < stringAmount.length; ++i) {
                char ch = [stringAmount characterAtIndex:i];
                [self postKeyEvent:ch]; // Feeds the local keystroke queue
            }
            return firstChar;
        } else {
            return c;
        }
    } else {
        // 3. Fallback: No brackets defined -> Pop virtual keyboard for raw input strings
        // (Note: Replace internal call with your newly exposed delegate methods)
        [self writeStringToWindowWithId:WIN_MESSAGE attribute:0 text:question];
        [self updateScreen];
        [self showKeyboard:YES];
        
        NethackEvent *e = [self fetchNextInputEvent];
        [self showKeyboard:NO];
        return e.key;
    }
}

/**
 * @brief Injects a raw key character event back into the application's event processing pipeline.
 *
 * This method is utilized by the core game engine to pass internal asynchronous keystroke signals 
 * or automated macro choices back out to the main application interface layer. The application 
 * consumes this value to update UI states, process textual macros, or feed downstream UI queues.
 *
 * @param ch The integer value representing the ASCII character or custom key token to be injected.
 *
 * @see fetchNextInputEvent
 * @see NetHackEngineDelegate
 */
- (void)postKeyEvent:(int)ch {
    [nethackEventQueue addKeyEvent:ch];
}

- (void)endMenuForWindowWithId:(int)wid prompt:(const char *)prompt {
    if (prompt) {
        // Look up the window from your dictionary
        Window *w = [windows objectForKey:@(wid)];
        
        // Safely apply the string property inside the app layer where it belongs
        w.menuPrompt = [NSString stringWithCString:prompt encoding:NSASCIIStringEncoding];
    }
}

- (int)selectMenuForWindowWithId:(int)wid how:(int)how selectedItems:(struct menu_item **)selected {
    // Look up the window from your private dictionary
    Window *w = [windows objectForKey:@(wid)];
    
    // Set the window properties exactly like your legacy code did
    w.menuHow = how;
    
    // Display the menu (which blocks this thread until user hits Done/Cancel)
    [self displayMenuWindow:w];
    
    // Assign the resulting NetHack item list pointer back to the engine
    *selected = w.menuList;
    
    // Clean up the prompt reference now that the menu lifecycle is finished
    w.menuPrompt = nil;
    
    // Return the raw integer count or outcome code
    return w.menuResult;
}

- (void)writeStringToWindowWithId:(winid)wid attribute:(int)attr text:(const char *)text {
    if (text) {
        Window *w = [windows objectForKey:@(wid)];
        [w putString:text];
    }
}

/**
 * @brief Expands tokenized character boundaries (e.g., 'a-c') into explicit sequential inventory letters ('abc').
 * @param lets The compressed inventory shorthand string token passed from the selection loops.
 * @return An expanded mutable string listing all legitimate item characters in order.
 */
- (NSString *)expandInventoryLetters:(NSString *)lets {
    NSMutableString *res = [NSMutableString string];
    char lastChar = 0; // Initialize to 0 for safety
    BOOL isRange = NO;
    
    for (int i = 0; i < lets.length; ++i) {
        char c = [lets characterAtIndex:i];
        if (isRange) {
            for (char ch = lastChar + 1; ch <= c; ++ch) {
                [res appendFormat:@"%c", ch]; // Use appendFormat for cleaner execution string expansion
            }
            isRange = NO;
        } else if (c == '-' && lastChar) {
            isRange = YES;
        } else {
            [res appendFormat:@"%c", c];
            lastChar = c;
        }
    }
    return res;
}

@end
