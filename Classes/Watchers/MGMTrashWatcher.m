//
//  MGMTrashWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/17/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
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