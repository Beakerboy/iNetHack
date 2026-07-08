//
//  FileLogger.m
//  iNetHack
//
//  Created by dirk on 11/25/09.
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

#include <fcntl.h>

#import "FileLogger.h"

@implementation FileLogger

/**
 * @brief Truncates the log file when it exceeds the maximum allowed size.
 *
 * This method monitors log growth. When the log file exceeds the configured 
 * `maxSize`, it isolates the younger half of the file payload, rolls forward to 
 * the nearest complete line boundary (newline character), and overwrites the 
 * file atomically with the remaining data tail.
 *
 * This prevents active logs from bloating device storage while preserving 
 * partial logs and maintaining correct formatting boundaries.
 */
- (void)resize {
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;
    
    // Fetch file attributes safely
    NSDictionary *attributes = [fm attributesOfItemAtPath:filename error:&error];
    if (!attributes) {
        NSLog(@"Error reading log attributes: %@", error.localizedDescription);
        return;
    }
    
    unsigned long long size = [attributes fileSize];
    if (size < maxSize) {
        return; // File is small enough; nothing to do
    }
    
    // Map the file securely using modern URLs
    NSURL *fileURL = [NSURL fileURLWithPath:filename];
    NSData *src = [[NSData alloc] initWithContentsOfURL:fileURL
                                                options:NSDataReadingMappedIfSafe
                                                  error:&error];
    if (!src || error) {
        NSLog(@"Error mapping log file: %@", error.localizedDescription);
        [src release]; // Only needed if project strictly forces Manual Reference Counting (MRC)
        return;
    }
    
    // Find the truncation point directly inside the mapped buffer
    unsigned long halfSize = maxSize / 2;
    unsigned long startOffset = (unsigned long)(size - halfSize);
    
    const char *bytes = (const char *)[src bytes];
    unsigned long scanOffset = 0;
    
    // Scan forward from the midpoint until we find the first safe newline character
    while ((startOffset + scanOffset) < size) {
        if (bytes[startOffset + scanOffset] == '\n') {
            scanOffset++; // Move past the newline character
            break;
        }
        scanOffset++;
    }
    
    // Guard against zero-byte slices or out-of-bounds anomalies
    unsigned long finalCutOffset = startOffset + scanOffset;
    if (finalCutOffset >= size) {
        finalCutOffset = startOffset; // Fallback to exact half-size split if no newline found
    }
    
    // Extract the remaining log tail and overwrite atomically
    NSRange remainingRange = NSMakeRange(finalCutOffset, (NSUInteger)(size - finalCutOffset));
    NSData *newData = [src subdataWithRange:remainingRange];
    
    // Write atomically to prevent log corruption if the app crashes mid-write
    [newData writeToURL:fileURL atomically:YES];
    
    // Clean up memory allocations manually (omit these two lines if project is using ARC)
    [src release];
}


- (instancetype) initWithFile:(NSString *)path maxSize:(int)ms {
	if (self = [super init]) {
		filename = [path copy];
		maxSize = ms;
		[self resize];
		fd = fopen([filename fileSystemRepresentation], "a");
	}
	return self;
}

- (instancetype) initWithFile:(NSString *)path {
	return [self initWithFile:path maxSize:4096];
}

- (void) logString:(NSString *)message {
	NSDate *date = [[NSDate alloc] init];
	NSString *ts = [date description];
	[date release];
	int size = (int) ts.length + 2;
	char dateBuffer[size];
	[ts getCString:dateBuffer maxLength:size encoding:NSASCIIStringEncoding];
	dateBuffer[size-2] = ' ';
	dateBuffer[size-1] = 0;
	fputs(dateBuffer, fd);
	size = (int) message.length + 2;
	char msg[size];
	[message getCString:msg maxLength:size encoding:NSASCIIStringEncoding];
	msg[size-2] = '\n';
	msg[size-1] = 0;
	fputs(msg, fd);
}

- (void) flush {
	fflush(fd);
}

- (void) dealloc {
	fclose(fd);
	[filename release];
	[super dealloc];
}

@end
