//
//  MGMKeyboardWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMKeyboardWatcher.h"
#import "MGMController.h"
#import <Carbon/Carbon.h>

OSStatus keyPushed(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	[(MGMKeyboardWatcher *)userData keyPushed];
	return (CallNextEventHandler(nextHandler, theEvent));
}

@implementation MGMKeyboardWatcher
- (id)init {
	if ((self = [super init])) {
		EventTypeSpec eventType;
		eventType.eventClass = kEventClassKeyboard;
		eventType.eventKind = kEventRawKeyDown;
		InstallEventHandler(GetEventMonitorTarget(), NewEventHandlerUPP(keyPushed), 1, &eventType, self, NULL);
	}
	return self;
}
- (void)dealloc {
	DisposeEventHandlerUPP(keyPushed);
	[super dealloc];
}

- (void)keyPushed {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"keypushed", MGMNName, @"Key Pushed", MGMNTitle, @"", MGMNDescription, nil]];
}
@end