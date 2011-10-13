//
//  MGMKeyboardWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/16/11.
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