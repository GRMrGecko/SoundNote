//
//  MGMLoginItems.m
//  SoundNote
//
//  Created by Mr. Gecko on 8/7/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). http://mrgeckosmedia.com/
//
//  Permission to use, copy, modify, and/or distribute this software for any purpose
//  with or without fee is hereby granted, provided that the above copyright notice
//  and this permission notice appear in all copies.
//
//  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH
//  REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT,
//  OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE,
//  DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
//  ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

#import "MGMLoginItems.h"

NSString * const MGMLoginItemsPath = @"~/Library/Preferences/loginwindow.plist";
NSString * const MGMItemsKey = @"AutoLaunchedApplicationDictionary";
NSString * const MGMPathKey = @"Path";
NSString * const MGMHideKey = @"Hide";

@implementation MGMLoginItems
+ (id)items {
	return [[[self alloc] init] autorelease];
}
- (id)init {
	if ((self = [super init])) {
		loginItems = [[NSMutableDictionary dictionaryWithContentsOfFile:[MGMLoginItemsPath stringByExpandingTildeInPath]] retain];
	}
	return self;
}
- (void)dealloc {
	[loginItems release];
	[super dealloc];
}

- (NSArray *)paths {
	NSMutableArray *returnApps = [NSMutableArray array];
	NSArray *applications = [loginItems objectForKey:MGMItemsKey];
	for (int i=0; i<[applications count]; i++) {
		[returnApps addObject:[[applications objectAtIndex:i] objectForKey:MGMPathKey]];
	}
	return returnApps;
}

- (BOOL)selfExists {
	return [self exists:[[NSBundle mainBundle] bundlePath]];
}
- (BOOL)addSelf {
	return [self add:[[NSBundle mainBundle] bundlePath]];
}
- (BOOL)removeSelf {
	return [self remove:[[NSBundle mainBundle] bundlePath]];
}

- (BOOL)exists:(NSString *)thePath {
	NSArray *applications = [loginItems objectForKey:MGMItemsKey];
	for (int i=0; i<[applications count]; i++) {
		if ([[[applications objectAtIndex:i] objectForKey:MGMPathKey] isEqual:thePath])
			return YES;
	}
	return NO;
}
- (BOOL)add:(NSString *)thePath {
	return [self add:thePath hide:NO];
}
- (BOOL)add:(NSString *)thePath hide:(BOOL)shouldHide {
	if ([self exists:thePath])
		return NO;
	NSMutableArray *applications = [NSMutableArray arrayWithArray:[loginItems objectForKey:MGMItemsKey]];
	NSMutableDictionary *info = [NSMutableDictionary dictionary];
	[info setObject:thePath forKey:MGMPathKey];
	[info setObject:[NSNumber numberWithBool:shouldHide] forKey:MGMHideKey];
	[applications addObject:info];
	[loginItems setObject:applications forKey:MGMItemsKey];
	[self _save];
	return YES;
}
- (BOOL)remove:(NSString *)thePath {
	NSMutableArray *applications = [NSMutableArray arrayWithArray:[loginItems objectForKey:MGMItemsKey]];
	for (int i=0; i<[applications count]; i++) {
		if ([[[applications objectAtIndex:i] objectForKey:MGMPathKey] isEqual:thePath]) {
			[applications removeObjectAtIndex:i];
			[loginItems setObject:applications forKey:MGMItemsKey];
			[self _save];
			return YES;
		}
	}
	return NO;
}

- (void)_save {
	[loginItems writeToFile:[MGMLoginItemsPath stringByExpandingTildeInPath] atomically:YES];
}
@end