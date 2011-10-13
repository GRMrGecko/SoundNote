//
//  MGMDisplayWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/15/11.
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

#import "MGMDisplayWatcher.h"
#import "MGMController.h"

@implementation MGMDisplayWatcher
- (id)init {
	if ((self = [super init])) {
		NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		[notificationCenter addObserver:self selector:@selector(screensDidSleep:) name:@"NSWorkspaceScreensDidSleepNotification" object:nil];
		[notificationCenter addObserver:self selector:@selector(screensDidWake:) name:@"NSWorkspaceScreensDidWakeNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeScreenParameters:) name:NSApplicationDidChangeScreenParametersNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(spaceChanged:) name:@"NSWorkspaceActiveSpaceDidChangeNotification" object:nil];
	}
	return self;
}
- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)screensDidSleep:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"screensdidsleep", MGMNName, @"Screens Did Sleep", MGMNTitle, @"Your screens went to sleep.", MGMNDescription, nil]];
}
- (void)screensDidWake:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"screenswakesleep", MGMNName, @"Screens Did Wake", MGMNTitle, @"Your screens woke up from sleep.", MGMNDescription, nil]];
}
- (void)didChangeScreenParameters:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"screenchange", MGMNName, @"Screen Changed", MGMNTitle, @"The screen parameters has been changed.", MGMNDescription, nil]];
}
- (void)spaceChanged:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"spacechanged", MGMNName, @"Space Changed", MGMNTitle, @"You changed spaces.", MGMNDescription, nil]];
}
@end