//
//  MGMMouseWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMMouseWatcher.h"
#import "MGMController.h"
#import <Carbon/Carbon.h>

OSStatus mouseClicked(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	[(MGMMouseWatcher *)userData mouseClicked];
	return (CallNextEventHandler(nextHandler, theEvent));
}

@implementation MGMMouseWatcher
- (id)init {
	if ((self = [super init])) {
		EventTypeSpec eventType;
		eventType.eventClass = kEventClassMouse;
		eventType.eventKind = kEventMouseDown;
		InstallEventHandler(GetEventMonitorTarget(), NewEventHandlerUPP(mouseClicked), 1, &eventType, self, NULL);
	}
	return self;
}
- (void)dealloc {
	DisposeEventHandlerUPP(mouseClicked);
	[super dealloc];
}

- (void)mouseClicked {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"mouseclicked", MGMNName, @"Mouse Clicked", MGMNTitle, @"", MGMNDescription, nil]];
}
@end