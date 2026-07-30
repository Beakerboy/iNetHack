//
//  ExtendedCommandViewController.m
//  iNetHack
//
//  Created by dirk on 7/6/09.
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
#import "ExtendedCommandViewController.h"
#import "AbstractMainViewController.h"

@implementation ExtendedCommandViewController

@synthesize result, filteredExtCmd, filteredExtCmdIndex, colorInvert;


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Allocate your cache tracker arrays ONCE during view setup
    filteredExtCmd = [[NSMutableArray alloc] init];
    filteredExtCmdIndex = [[NSMutableArray alloc] init];
    
    // Let your engine subclass populate the safe string data once before display
    [self.mainViewController filterExtendedCommandsIntoNames:filteredExtCmd 
                                                     indices:filteredExtCmdIndex];
}
- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	result = -1;
    colorInvert = [[NSUserDefaults standardUserDefaults] floatForKey:@"colorInvert"];
	UITableView *tv = (UITableView *) self.view;
    tv.backgroundColor = !colorInvert?[UIColor blackColor]:[UIColor whiteColor];
    tv.separatorStyle = UITableViewCellSeparatorStyleNone;
    //iNethack2: Update iOS9: this scrolling fix no longer needed. Commenting out.
    /*
    long bottom;
    bottom= (self.view.frame.size.height + self.view.frame.origin.y) - [ExtendedCommandViewController screenSize].height;
    [tv setContentInset:UIEdgeInsetsMake(0, 0, bottom, 0)];
     */
}

- (void)viewWillDisappear:(BOOL)animated {
	if (result == -1) {
		[[MainViewController instance] broadcastUIEvent];
	}
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

#pragma mark UITableView delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	int row = (int) [indexPath row];
    result = [(NSNumber *) [filteredExtCmdIndex objectAtIndex: row] intValue];
	[[MainViewController instance] broadcastUIEvent];
	[self.navigationController popToRootViewControllerAnimated:NO];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	[self tableView:tableView didSelectRowAtIndexPath:indexPath];
}

#pragma mark UITableView datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return filteredExtCmd.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellId = @"extendedCommandViewControllerCellId";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId];
    if (!cell) {
        // Updated to modern UITableViewCell layout constructor (MRC safe)
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellId] autorelease];
        cell.backgroundColor = !colorInvert ? [UIColor blackColor] : [UIColor whiteColor];
        cell.textLabel.textColor = colorInvert ? [UIColor blackColor] : [UIColor whiteColor];
    }
    
    int row = (int)[indexPath row];
    
    // Pull the pre-extracted string name straight out of your optimized names cache array
    NSString *commandName = [filteredExtCmd objectAtIndex:row];
    
    // Format the display label cleanly using the Objective-C string
    cell.textLabel.text = [commandName capitalizedString];
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    return cell;
}

- (void)dealloc {
    [filteredExtCmd release];
    [filteredExtCmdIndex release];
    [super dealloc];
}


@end
