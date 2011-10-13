//
//  MGMApplicationWatcher.m
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

#import "MGMApplicationWatcher.h"
#import "MGMController.h"
#import <GeckoReporter/GeckoReporter.h>
#import <Carbon/Carbon.h>

NSString * const MGMNSApplicationName = @"NSApplicationName";
NSString * const MGMNSApplicationPath = @"NSApplicationPath";
NSString * const MGMNSWorkspaceApplicationKey = @"NSWorkspaceApplicationKey";

OSStatus frontAppChanged(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
	ProcessSerialNumber thisProcess;
	GetCurrentProcess(&thisProcess);
	ProcessSerialNumber newProcess;
	GetFrontProcess(&newProcess);
	Boolean same;
	SameProcess(&newProcess, &thisProcess, &same);
	if (!same)
		[(MGMApplicationWatcher *)userData frontApplicationChangedTo:&newProcess];
    return (CallNextEventHandler(nextHandler, theEvent));
}

@class NSRunningApplication;

@implementation MGMApplicationWatcher
- (id)init {
	if ((self = [super init])) {
		EventTypeSpec eventType;
		eventType.eventClass = kEventClassApplication;
		eventType.eventKind = kEventAppFrontSwitched;
		InstallApplicationEventHandler(NewEventHandlerUPP(frontAppChanged), 1, &eventType, self, NULL);
		
		NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		[notificationCenter addObserver:self selector:@selector(applicationWillLaunch:) name:NSWorkspaceWillLaunchApplicationNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
		if ([[MGMSystemInfo info] isAfterSnowLeopard]) {
			[notificationCenter addObserver:self selector:@selector(applicationDidHide:) name:@"NSWorkspaceDidHideApplicationNotification" object:nil];
			[notificationCenter addObserver:self selector:@selector(applicationDidUnhide:) name:@"NSWorkspaceDidUnhideApplicationNotification" object:nil];
		}
	}
	return self;
}
- (void)dealloc {
	DisposeEventHandlerUPP(frontAppChanged);
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}

- (void)frontApplicationChangedTo:(ProcessSerialNumber *)theProcess {
	NSDictionary *information = (NSDictionary *)ProcessInformationCopyDictionary(theProcess, kProcessDictionaryIncludeAllInformationMask);
	if ([[information objectForKey:(NSString *)kCFBundleNameKey] isEqual:@"SecurityAgent"])
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"passworddialogopened", MGMNName, @"Password Dialog Opened", MGMNTitle, @"The system is requesting you enter your password.", MGMNDescription, nil]];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationbecamefront", MGMNName, @"Application Became Front", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:@"BundlePath"]], MGMNIcon, nil]];
	[information release];
}
- (void)applicationWillLaunch:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationwilllaunch", MGMNName, @"Application Will Launch", MGMNTitle, [[theNotification userInfo] objectForKey:MGMNSApplicationName], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[[theNotification userInfo] objectForKey:MGMNSApplicationPath]], MGMNIcon, nil]];
}
- (void)applicationDidLaunch:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationdidlaunch", MGMNName, @"Application Did Launch", MGMNTitle, [[theNotification userInfo] objectForKey:MGMNSApplicationName], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[[theNotification userInfo] objectForKey:MGMNSApplicationPath]], MGMNIcon, nil]];
}
- (void)applicationDidTerminate:(NSNotification *)theNotification {
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationdidterminate", MGMNName, @"Application Did Terminate", MGMNTitle, [[theNotification userInfo] objectForKey:MGMNSApplicationName], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[[theNotification userInfo] objectForKey:MGMNSApplicationPath]], MGMNIcon, nil]];
}
- (void)applicationDidHide:(NSNotification *)theNotification {
	NSRunningApplication *application = [[theNotification userInfo] objectForKey:MGMNSWorkspaceApplicationKey];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationdidhide", MGMNName, @"Application Did Hide", MGMNTitle, [application localizedName], MGMNDescription, [application icon], MGMNIcon, nil]];
}
- (void)applicationDidUnhide:(NSNotification *)theNotification {
	NSRunningApplication *application = [[theNotification userInfo] objectForKey:MGMNSWorkspaceApplicationKey];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationdidunhide", MGMNName, @"Application Did Unhide", MGMNTitle, [application localizedName], MGMNDescription, [application icon], MGMNIcon, nil]];
}
@end