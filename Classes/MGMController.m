//
//  MGMController.m
//  SoundNote
//
//  Created by Mr. Gecko on 7/4/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMController.h"
#import "MGMFileManager.h"
#import "MGMLoginItems.h"
#import "MGMSound.h"
#import <GeckoReporter/GeckoReporter.h>
#import <Growl/GrowlApplicationBridge.h>

#import "MGMDisplayWatcher.h"
#import "MGMApplicationWatcher.h"
#import "MGMVolumeWatcher.h"
#import "MGMITunesWatcher.h"
#import "MGMUSBWatcher.h"
#import "MGMBluetoothWatcher.h"
#import "MGMNetworkWatcher.h"
#import "MGMPowerWatcher.h"
#import "MGMKeyboardWatcher.h"
#import "MGMMouseWatcher.h"
#import "MGMAccessibleWatcher.h"
#import "MGMTrashWatcher.h"

static NSAutoreleasePool *pool = nil;

void runloop(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info) {
	if (activity & kCFRunLoopEntry) {
		if (pool!=nil) [pool drain];
		pool = [NSAutoreleasePool new];
	} else if (activity & kCFRunLoopExit) {
		[pool drain];
		pool = nil;
	}
}

NSString * const MGMCopyright = @"Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/";
NSString * const MGMVersion = @"MGMVersion";
NSString * const MGMLaunchCount = @"MGMLaunchCount";

NSString * const MGMApplicationSupportPath = @"~/Library/Application Support/MrGeckosMedia/SoundNote/";
NSString * const MGMNotesName = @"notes.txt";
NSString * const MGMGrowlName = @"growl.plist";
NSString * const MGMDisabledName = @"disabled.plist";
NSString * const MGMSoundEndedNotification = @"MGMSoundEndedNotification";

NSString * const MGMNName = @"MGMNName";
NSString * const MGMNTitle = @"MGMNTitle";
NSString * const MGMNDescription = @"MGMNDescription";
NSString * const MGMNIcon = @"MGMNIcon";
NSString * const MGMNSound = @"MGMNSound";
NSString * const MGMNTask = @"MGMNTask";

@protocol NSFileManagerProtocol <NSObject>
- (BOOL)createDirectoryAtPath:(NSString *)path withIntermediateDirectories:(BOOL)createIntermediates attributes:(NSDictionary *)attributes error:(NSError **)error;
- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes;

- (BOOL)removeItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL)removeFileAtPath:(NSString *)path handler:(id)handler;

- (BOOL)copyItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)copyPath:(NSString *)source toPath:(NSString *)destination handler:(id)handler;

- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError **)error;
- (BOOL)movePath:(NSString *)source toPath:(NSString *)destination handler:(id)handler;
@end

static MGMController *MGMSharedController;

@implementation MGMController
+ (id)sharedController {
	if (MGMSharedController==nil) {
		MGMSharedController = [MGMController new];
	}
	return MGMSharedController;
}
- (id)init {
	if (MGMSharedController!=nil) {
		if ((self = [super init]))
			[self release];
		self = MGMSharedController;
	} else if ((self = [super init])) {
		MGMSharedController = self;
	}
	return self;
}
- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setup) name:MGMGRDoneNotification object:nil];
	[MGMReporter sharedReporter];
}
- (void)setup {
	CFRunLoopObserverContext  context = {0, self, NULL, NULL, NULL};
	CFRunLoopObserverRef observer = CFRunLoopObserverCreate(kCFAllocatorDefault, kCFRunLoopEntry | kCFRunLoopExit, YES, 0, runloop, &context);
	CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
	
	[GrowlApplicationBridge setGrowlDelegate:nil];
	
	[[MGMLoginItems items] addSelf];
	
	NSFileManager *manager = [NSFileManager defaultManager];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if ([defaults objectForKey:MGMVersion]==nil) {
		if ([manager fileExistsAtPath:[MGMApplicationSupportPath stringByExpandingTildeInPath]]) {
			[manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:[MGMNotesName stringByDeletingPathExtension] ofType:[MGMNotesName pathExtension]] toPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMNotesName]];
			[manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:[MGMGrowlName stringByDeletingPathExtension] ofType:[MGMGrowlName pathExtension]] toPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMGrowlName]];
			[manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:[MGMDisabledName stringByDeletingPathExtension] ofType:[MGMDisabledName pathExtension]] toPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMDisabledName]];
			[manager removeItemAtPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:@"note.txt"]];
			[self showInstructions];
			[defaults setObject:[[MGMSystemInfo info] applicationVersion] forKey:MGMVersion];
		}
	}
	[self registerDefaults];
	if (![manager fileExistsAtPath:[MGMApplicationSupportPath stringByExpandingTildeInPath]]) {
		[manager createDirectoryAtPath:[MGMApplicationSupportPath stringByExpandingTildeInPath] withAttributes:nil];
		[manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:[MGMNotesName stringByDeletingPathExtension] ofType:[MGMNotesName pathExtension]] toPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMNotesName]];
		[manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:[MGMGrowlName stringByDeletingPathExtension] ofType:[MGMGrowlName pathExtension]] toPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMGrowlName]];
		[manager copyItemAtPath:[[NSBundle mainBundle] pathForResource:[MGMDisabledName stringByDeletingPathExtension] ofType:[MGMDisabledName pathExtension]] toPath:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMDisabledName]];
		[self showInstructions];
	}
	
	NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
	[notificationCenter addObserver:self selector:@selector(willLogout:) name:NSWorkspaceWillPowerOffNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(willSleep:) name:NSWorkspaceWillSleepNotification object:nil];
	[notificationCenter addObserver:self selector:@selector(didWake:) name:NSWorkspaceDidWakeNotification object:nil];
	
	watchers = [NSMutableArray new];
	notifications = [NSMutableArray new];
	[self startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"login", MGMNName, @"Login", MGMNTitle, @"You have logged in.", MGMNDescription, nil]];
	
	
	NSDictionary *disabledWatchers = [NSDictionary dictionaryWithContentsOfFile:[[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMDisabledName]];
	if (![[disabledWatchers objectForKey:@"display"] boolValue])
		[self registerWatcher:[[MGMDisplayWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"application"] boolValue])
		[self registerWatcher:[[MGMApplicationWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"volume"] boolValue])
		[self registerWatcher:[[MGMVolumeWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"itunes"] boolValue])
		[self registerWatcher:[[MGMITunesWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"usb"] boolValue])
		[self registerWatcher:[[MGMUSBWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"bluetooth"] boolValue])
		[self registerWatcher:[[MGMBluetoothWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"network"] boolValue])
		[self registerWatcher:[[MGMNetworkWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"power"] boolValue])
		[self registerWatcher:[[MGMPowerWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"keyboard"] boolValue])
		[self registerWatcher:[[MGMKeyboardWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"mouse"] boolValue])
		[self registerWatcher:[[MGMMouseWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"accessible"] boolValue])
		[self registerWatcher:[[MGMAccessibleWatcher new] autorelease]];
	if (![[disabledWatchers objectForKey:@"trash"] boolValue])
		[self registerWatcher:[[MGMTrashWatcher new] autorelease]];
	
	if ([defaults integerForKey:MGMLaunchCount]!=5) {
		[defaults setInteger:[defaults integerForKey:MGMLaunchCount]+1 forKey:MGMLaunchCount];
		if ([defaults integerForKey:MGMLaunchCount]==5) {
			NSAlert *alert = [[NSAlert new] autorelease];
			[alert setMessageText:@"Donations"];
			[alert setInformativeText:@"Thank you for using SoundNote. SoundNote is donation supported software. If you like using it, please consider giving a donation to help with development."];
			[alert addButtonWithTitle:@"Yes"];
			[alert addButtonWithTitle:@"No"];
			int result = [alert runModal];
			if (result==1000)
				[self donate:self];
		}
	}
}
- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[watchers release];
	[notifications release];
	[wakeTimer invalidate];
	[wakeTimer release];
	[lastUpdated release];
	[growl release];
	[super dealloc];
}

- (void)registerDefaults {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults setObject:[NSNumber numberWithInt:1] forKey:MGMLaunchCount];
	[[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}
- (BOOL)applicationShouldHandleReopen:(NSApplication *)theApplication hasVisibleWindows:(BOOL)flag {
	[self showInstructions];
	return YES;
}
- (IBAction)donate:(id)sender {
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=LMT7LSBTP4NDJ"]];
}

- (void)showInstructions {
	if (instructions==nil) {
		NSRect size = NSMakeRect(0, 0, 450, 400);
		instructions = [[NSWindow alloc] initWithContentRect:size styleMask:NSTitledWindowMask | NSClosableWindowMask backing:NSBackingStoreBuffered defer:NO];
		[instructions setTitle:@"SoundNote"];
		NSScrollView *scrollview = [[[NSScrollView alloc] initWithFrame:size] autorelease];
		[scrollview setHasVerticalScroller:YES];
		[scrollview setHasHorizontalScroller:NO];
		NSSize contentSize = [scrollview contentSize];
		NSTextView *textView = [[[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, contentSize.width, contentSize.height)] autorelease];
		[textView readRTFDFromFile:[[NSBundle mainBundle] pathForResource:@"Instructions" ofType:@"rtf"]];
		[textView setEditable:NO];
		[textView setVerticallyResizable:YES];
		[textView setHorizontallyResizable:NO];
		[textView setAutoresizingMask:NSViewHeightSizable];
		[scrollview setDocumentView:textView];
		[[textView textContainer] setHeightTracksTextView:YES];
		[instructions setContentView:scrollview];
		[instructions setDelegate:self];
		[instructions setLevel:NSStatusWindowLevel];
		[instructions setReleasedWhenClosed:YES];
		[instructions center];
	}
	[instructions makeKeyAndOrderFront:self];
	[[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
}
- (void)windowWillClose:(NSNotification *)theNotification {
	instructions = nil;
	[[NSWorkspace sharedWorkspace] selectFile:[MGMApplicationSupportPath stringByExpandingTildeInPath] inFileViewerRootedAtPath:[MGMApplicationSupportPath stringByExpandingTildeInPath]];
}

- (void)registerWatcher:(id)theWatcher {
	[watchers addObject:theWatcher];
}
- (NSMutableDictionary *)startNotificationWithInfo:(NSDictionary *)theInfo {
	NSArray *allowedNotifications = [NSArray arrayWithObjects:@"logout", @"willsleep", @"didwake", nil];
	if (ignoreNotifications && ![allowedNotifications containsObject:[theInfo objectForKey:MGMNName]])
		return nil;
	//NSLog(@"%@", theInfo);
	NSArray *allowedExtensions = [NSArray arrayWithObjects:@"aiff", @"aif", @"mp3", @"wav", @"au", @"m4a", nil];
	NSMutableDictionary *info = [[theInfo mutableCopy] autorelease];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSArray *files = [manager contentsOfDirectoryAtPath:[MGMApplicationSupportPath stringByExpandingTildeInPath]];
	for (int i=0; i<[files count]; i++) {
		if ([[[files objectAtIndex:i] stringByDeletingPathExtension] isEqual:[info objectForKey:MGMNName]]) {
			NSString *path = [[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:[files objectAtIndex:i]];
			if ([allowedExtensions containsObject:[[path pathExtension] lowercaseString]]) {
				MGMSound *sound = [[[MGMSound alloc] initWithContentsOfFile:path] autorelease];
				[info setObject:sound forKey:MGMNSound];
				[notifications addObject:info];
				[sound setDelegate:self];
				[sound play];
			} else if ([[[path pathExtension] lowercaseString] isEqual:@"sh"]) {
				NSTask *task = [[NSTask new] autorelease];
				[task setLaunchPath:@"/bin/bash"];
				NSMutableArray *arguments = [NSMutableArray arrayWithObject:path];
				[arguments addObject:[info objectForKey:MGMNDescription]];
				[task setArguments:arguments];
				[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidTerminate:) name:NSTaskDidTerminateNotification object:task];
				[info setObject:task forKey:MGMNTask];
				[notifications addObject:info];
				[task launch];
			}
		}
	}
	
	NSString *growlPath = [[MGMApplicationSupportPath stringByExpandingTildeInPath] stringByAppendingPathComponent:MGMGrowlName];
	NSDictionary *attributes = [manager attributesOfItemAtPath:growlPath];
	if (![[attributes objectForKey:NSFileModificationDate] isEqual:lastUpdated]) {
		[growl release];
		growl = [[NSDictionary dictionaryWithContentsOfFile:growlPath] retain];
		[lastUpdated release];
		lastUpdated = [[attributes objectForKey:NSFileModificationDate] retain];
	}
	if ([[growl objectForKey:[info objectForKey:MGMNName]] boolValue]) {
		NSData *icon = nil;
		if ([[info objectForKey:MGMNIcon] isKindOfClass:[NSData class]])
			icon = [info objectForKey:MGMNIcon];
		else if ([[info objectForKey:MGMNIcon] isKindOfClass:[NSImage class]])
			icon = [[info objectForKey:MGMNIcon] TIFFRepresentation];
		else
			icon = [[[NSApplication sharedApplication] applicationIconImage] TIFFRepresentation];
		[GrowlApplicationBridge notifyWithTitle:[info objectForKey:MGMNTitle] description:[info objectForKey:MGMNDescription] notificationName:[info objectForKey:MGMNName] iconData:icon priority:0 isSticky:NO clickContext:nil];
	}
	return info;
}
- (NSMutableDictionary *)notificationWithName:(NSString *)theName {
	for (int i=0; i<[notifications count]; i++) {
		if ([[[notifications objectAtIndex:i] objectForKey:MGMNName] isEqual:theName])
			return [notifications objectAtIndex:i];
	}
	return nil;
}
- (void)soundDidFinishPlaying:(MGMSound *)theSound {
	for (int i=0; i<[notifications count]; i++) {
		if ([[notifications objectAtIndex:i] objectForKey:MGMNSound]==theSound) {
			NSMutableDictionary *notification = [notifications objectAtIndex:i];
			[notification removeObjectForKey:MGMNSound];
			[[NSNotificationCenter defaultCenter] postNotificationName:MGMSoundEndedNotification object:notification];
			if ([notification objectForKey:MGMNTask]==nil)
				[notifications removeObject:notification];
		}
	}
}
- (void)taskDidTerminate:(NSNotification *)theNotification {
	[[NSNotificationCenter defaultCenter] removeObserver:self name:[theNotification name] object:[theNotification object]];
	for (int i=0; i<[notifications count]; i++) {
		if ([[notifications objectAtIndex:i] objectForKey:MGMNTask]==[theNotification object]) {
			NSMutableDictionary *notification = [notifications objectAtIndex:i];
			[notification removeObjectForKey:MGMNTask];
			if ([notification objectForKey:MGMNSound]==nil)
				[notifications removeObject:notification];
		}
	}
}

- (void)willLogout:(NSNotification *)theNotification {
	ignoreNotifications = YES;
	[self startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"logout", MGMNName, @"Logout", MGMNTitle, @"You are logging out.", MGMNDescription, nil]];
}
- (void)willSleep:(NSNotification *)theNotification {
	if (wakeTimer!=nil) {
		[wakeTimer invalidate];
		[wakeTimer release];
		wakeTimer = nil;
	}
	ignoreNotifications = YES;
	NSMutableDictionary *info = [self startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"willsleep", MGMNName, @"Will Sleep", MGMNTitle, @"The computer will go to sleep.", MGMNDescription, nil]];
	if ([info objectForKey:MGMNSound]!=nil) {
		while ([[info objectForKey:MGMNSound] isPlaying]) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		}
	}
}
- (void)didWake:(NSNotification *)theNotification {
	[self startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"didwake", MGMNName, @"Did Wake", MGMNTitle, @"The computer woke up from sleep.", MGMNDescription, nil]];
	wakeTimer = [[NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(sendWakeNotification) userInfo:nil repeats:NO] retain];
}
- (void)sendWakeNotification {
	[wakeTimer release];
	wakeTimer = nil;
	ignoreNotifications = NO;
}

- (IBAction)Quit:(id)sender {
	[[MGMLoginItems items] removeSelf];
	[[NSApplication sharedApplication] terminate:self];
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
	NSMutableDictionary *info = [self notificationWithName:@"logout"];
	if ([info objectForKey:MGMNSound]!=nil) {
		while ([[info objectForKey:MGMNSound] isPlaying]) {
			[NSThread sleepUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
		}
	}
	return NSTerminateNow;
}
@end
