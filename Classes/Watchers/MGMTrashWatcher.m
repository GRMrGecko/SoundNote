//
//  MGMTrashWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/17/11.
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

#import "MGMTrashWatcher.h"
#import "MGMController.h"
#import "MGMPathSubscriber.h"
#import "MGMFileManager.h"

NSString * const MGMTrashFolder = @"~/.Trash";

@implementation MGMTrashWatcher
- (id)init {
	if ((self = [super init])) {
		NSFileManager *manager = [NSFileManager defaultManager];
		lastCount = [[manager contentsOfDirectoryAtPath:[MGMTrashFolder stringByExpandingTildeInPath]] count];
		trashWatcher = [MGMPathSubscriber new];
		[trashWatcher setDelegate:self];
		[trashWatcher addPath:[MGMTrashFolder stringByExpandingTildeInPath]];
	}
	return self;
}
- (void)dealloc {
	[trashWatcher release];
	[super dealloc];
}

- (void)subscribedPathChanged:(NSString *)thePath {
	NSFileManager *manager = [NSFileManager defaultManager];
	int count = [[manager contentsOfDirectoryAtPath:[MGMTrashFolder stringByExpandingTildeInPath]] count];
	if (count>lastCount) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"movedtotrash", MGMNName, @"Moved to Trash", MGMNTitle, @"An item was moved to the trash.", MGMNDescription, nil]];
	} else if (lastCount!=count && count==0) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"trashemptied", MGMNName, @"Trash Emptied", MGMNTitle, @"The trash was emptied.", MGMNDescription, nil]];
	}
	lastCount = count;
}
@end