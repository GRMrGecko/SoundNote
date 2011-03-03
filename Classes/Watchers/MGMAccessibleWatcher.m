//
//  MGMAccessibleWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/17/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMAccessibleWatcher.h"
#import "MGMController.h"
#import <GeckoReporter/GeckoReporter.h>

NSString *MGMANSApplicationProcessIdentifier = @"NSApplicationProcessIdentifier";
NSString *MGMANSApplicationName = @"NSApplicationName";
NSString *MGMBundlePath = @"BundlePath";

static void receivedNotification(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
	pid_t pid = 0;
	AXUIElementGetPid(element, &pid);
	ProcessSerialNumber process;
	GetProcessForPID(pid, &process);
	[(MGMAccessibleWatcher *)refcon receivedNotification:(NSString *)notification process:&process element:element];
}

@implementation MGMAccessibleWatcher
- (id)init {
	if ((self = [super init])) {
		if (!AXAPIEnabled()) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"'Enable access for assistive devices' is not enabled."];
			[alert setInformativeText:@"For Accessible Notifications to work, you must have 'Enable access for assistive devices' in the 'Universal Access' preferences panel enabled. Once you have enabled this, you can quit SoundNote by opening it in the finder and pressing command (apple) and the q key and relaunch it to gain these features."];
			[alert runModal];
		} else {
			observers = [NSMutableDictionary new];
			NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
			[notificationCenter addObserver:self selector:@selector(applicationDidLaunch:) name:NSWorkspaceDidLaunchApplicationNotification object:nil];
			[notificationCenter addObserver:self selector:@selector(applicationDidTerminate:) name:NSWorkspaceDidTerminateApplicationNotification object:nil];
			
			NSArray *applications = [[NSWorkspace sharedWorkspace] launchedApplications];
			for (int i=0; i<[applications count]; i++) {
				[self registerObserversFor:[applications objectAtIndex:i]];
			}
		}
	}
	return self;
}
- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	NSArray *keys = [observers allKeys];
	for (int i=0; i<[keys count]; i++) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource((AXObserverRef)[observers objectForKey:[keys objectAtIndex:i]]), kCFRunLoopDefaultMode);
	}
	[observers release];
	[super dealloc];
}

- (void)applicationDidLaunch:(NSNotification *)theNotification {
	[self registerObserversFor:[theNotification userInfo]];
}
- (void)applicationDidTerminate:(NSNotification *)theNotification {
	NSNumber *pidNumber = [[theNotification userInfo] objectForKey:MGMANSApplicationProcessIdentifier];
	AXObserverRef observer = (AXObserverRef)[observers objectForKey:pidNumber];
	if (observer!=NULL) {
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
        [observers removeObjectForKey:pidNumber];
    }
}

- (void)observe:(CFStringRef)theNotification element:(AXUIElementRef)theElement observer:(AXObserverRef)theObserver application:(NSDictionary *)theApplication {
	if (AXObserverAddNotification(theObserver, theElement, theNotification, self)!=kAXErrorSuccess)
		NSLog(@"Unable to observe %@ for %@.", (NSString *)theNotification, [theApplication valueForKey:MGMANSApplicationName]);
}
- (void)registerObserversFor:(NSDictionary *)theApplication {
	NSNumber *pidNumber = [theApplication objectForKey:MGMANSApplicationProcessIdentifier];
    if ([pidNumber intValue]!=getpid()) {
        if (![observers objectForKey:pidNumber]) {
            pid_t pid = (pid_t)[pidNumber intValue];
            AXObserverRef observer;
            if (AXObserverCreate(pid, receivedNotification, &observer)==kAXErrorSuccess) {
                CFRunLoopAddSource(CFRunLoopGetCurrent(), AXObserverGetRunLoopSource(observer), kCFRunLoopDefaultMode);
                AXUIElementRef element = AXUIElementCreateApplication(pid);
				[self observe:kAXFocusedWindowChangedNotification element:element observer:observer application:theApplication];
				[self observe:kAXWindowCreatedNotification element:element observer:observer application:theApplication];
				[self observe:kAXWindowMiniaturizedNotification element:element observer:observer application:theApplication];
				[self observe:kAXWindowDeminiaturizedNotification element:element observer:observer application:theApplication];
				[self observe:kAXDrawerCreatedNotification element:element observer:observer application:theApplication];
				[self observe:kAXSheetCreatedNotification element:element observer:observer application:theApplication];
				[self observe:kAXMenuOpenedNotification element:element observer:observer application:theApplication];
				[self observe:kAXMenuClosedNotification element:element observer:observer application:theApplication];
				[self observe:kAXMenuItemSelectedNotification element:element observer:observer application:theApplication];
				[self observe:kAXRowExpandedNotification element:element observer:observer application:theApplication];
				[self observe:kAXRowCollapsedNotification element:element observer:observer application:theApplication];
				[self observe:kAXSelectedRowsChangedNotification element:element observer:observer application:theApplication];
				if (![[MGMSystemInfo info] isAfterSnowLeopard]) {
					[self observe:kAXApplicationHiddenNotification element:element observer:observer application:theApplication];
					[self observe:kAXApplicationShownNotification element:element observer:observer application:theApplication];
				}
				[observers setObject:(id)observer forKey:pidNumber];
				CFRelease(observer);
				CFRelease(element);
            } else {
				NSLog(@"Unable to create observer for %@.", [theApplication valueForKey:MGMANSApplicationName]);
            }
        }
    }
}

- (void)receivedNotification:(NSString *)theName process:(ProcessSerialNumber *)theProcess element:(AXUIElementRef)theElement {
	NSDictionary *information = (NSDictionary *)ProcessInformationCopyDictionary(theProcess, kProcessDictionaryIncludeAllInformationMask);
	if ([theName isEqual:(NSString *)kAXFocusedWindowChangedNotification]) {
		CFTypeRef title;
		AXUIElementCopyAttributeValue(theElement, CFSTR("AXTitle"), &title);
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"focusedwindowchanged", MGMNName, @"Focused Window Changed", MGMNTitle, [NSString stringWithFormat:@"%@ in %@", (NSString *)title, [information objectForKey:(NSString *)kCFBundleNameKey]], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
		if (title!=NULL)
			CFRelease(title);
	} else if ([theName isEqual:(NSString *)kAXWindowCreatedNotification]) {
		CFTypeRef title;
		AXUIElementCopyAttributeValue(theElement, CFSTR("AXTitle"), &title);
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"windowcreated", MGMNName, @"Window Created", MGMNTitle, [NSString stringWithFormat:@"%@ in %@", (NSString *)title, [information objectForKey:(NSString *)kCFBundleNameKey]], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
		if (title!=NULL)
			CFRelease(title);
	} else if ([theName isEqual:(NSString *)kAXWindowMiniaturizedNotification]) {
		CFTypeRef title;
		AXUIElementCopyAttributeValue(theElement, CFSTR("AXTitle"), &title);
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"windowminiaturized", MGMNName, @"Window Miniaturized", MGMNTitle, [NSString stringWithFormat:@"%@ in %@", (NSString *)title, [information objectForKey:(NSString *)kCFBundleNameKey]], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
		if (title!=NULL)
			CFRelease(title);
	} else if ([theName isEqual:(NSString *)kAXWindowDeminiaturizedNotification]) {
		CFTypeRef title;
		AXUIElementCopyAttributeValue(theElement, CFSTR("AXTitle"), &title);
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"windowdeminiaturized", MGMNName, @"Window Deminiaturized", MGMNTitle, [NSString stringWithFormat:@"%@ in %@", (NSString *)title, [information objectForKey:(NSString *)kCFBundleNameKey]], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
		if (title!=NULL)
			CFRelease(title);
	} else if ([theName isEqual:(NSString *)kAXDrawerCreatedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"drawercreated", MGMNName, @"Drawer Created", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXSheetCreatedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"sheetcreated", MGMNName, @"Sheet Created", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXMenuOpenedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"menuopened", MGMNName, @"Menu Opened", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXMenuClosedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"menuclosed", MGMNName, @"Menu Closed", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXMenuItemSelectedNotification]) {
		CFTypeRef title;
		AXUIElementCopyAttributeValue(theElement, CFSTR("AXTitle"), &title);
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"menuitemselected", MGMNName, @"Menu Item Selected", MGMNTitle, [NSString stringWithFormat:@"%@ in %@", (NSString *)title, [information objectForKey:(NSString *)kCFBundleNameKey]], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
		if (title!=NULL)
			CFRelease(title);
	} else if ([theName isEqual:(NSString *)kAXRowExpandedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rowexpanded", MGMNName, @"Row Expanded", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXRowCollapsedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"rowcollapsed", MGMNName, @"Row Collapsed", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXSelectedRowsChangedNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"selectedrowschanged", MGMNName, @"Selected Rows Changed", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXApplicationHiddenNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationdidhide", MGMNName, @"Application Did Hide", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	} else if ([theName isEqual:(NSString *)kAXApplicationShownNotification]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"applicationdidunhide", MGMNName, @"Application Did Unhide", MGMNTitle, [information objectForKey:(NSString *)kCFBundleNameKey], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[information objectForKey:MGMBundlePath]], MGMNIcon, nil]];
	}
	[information release];
}
@end