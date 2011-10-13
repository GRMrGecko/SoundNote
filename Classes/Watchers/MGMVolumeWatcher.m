//
//  MGMVolumeWatcher.m
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

#import "MGMVolumeWatcher.h"
#import "MGMController.h"
#import "MGMMD5.h"
#import "MGMFileManager.h"

NSString * const MGMCachePath = @"~/Library/Caches/com.MrGeckosMedia.SoundNote/";
NSString * const MGMNSWorkspaceVolumeLocalizedNameKey = @"NSWorkspaceVolumeLocalizedNameKey";
NSString * const MGMNSDevicePath = @"NSDevicePath";

@implementation MGMVolumeWatcher
- (id)init {
	if ((self = [super init])) {
		NSFileManager *manager = [NSFileManager defaultManager];
		if ([manager fileExistsAtPath:[MGMCachePath stringByExpandingTildeInPath]]) {
			[manager removeItemAtPath:[MGMCachePath stringByExpandingTildeInPath]];
			[manager createDirectoryAtPath:[MGMCachePath stringByExpandingTildeInPath] withAttributes:nil];
		} else {
			[manager createDirectoryAtPath:[MGMCachePath stringByExpandingTildeInPath] withAttributes:nil];
		}
		NSNotificationCenter *notificationCenter = [[NSWorkspace sharedWorkspace] notificationCenter];
		[notificationCenter addObserver:self selector:@selector(volumeRenamed:) name:@"NSWorkspaceDidRenameVolumeNotification" object:nil];
		[notificationCenter addObserver:self selector:@selector(didMountDrive:) name:NSWorkspaceDidMountNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(willUnmountDrive:) name:NSWorkspaceWillUnmountNotification object:nil];
		[notificationCenter addObserver:self selector:@selector(didUnmountDrive:) name:NSWorkspaceDidUnmountNotification object:nil];
	}
	return self;
}
- (void)dealloc {
	[[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
	[super dealloc];
}

- (void)volumeRenamed:(NSNotification *)theNotification {
	NSString *oldPath = [[[theNotification userInfo] objectForKey:@"NSWorkspaceVolumeOldURLKey"] path];
	NSString *newPath = [[[theNotification userInfo] objectForKey:@"NSWorkspaceVolumeURLKey"] path];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:newPath];
	if ([manager fileExistsAtPath:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[oldPath MD5]]]) {
		[manager moveItemAtPath:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[oldPath MD5]] toPath:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[newPath MD5]]];
	} else {
		[[icon TIFFRepresentation] writeToFile:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[newPath MD5]] atomically:NO];
	}
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"volumerenamed", MGMNName, @"Volume Renamed", MGMNTitle, [NSString stringWithFormat:@"%@ is now %@.", [[theNotification userInfo] objectForKey:@"NSWorkspaceVolumeOldLocalizedNameKey"], [[theNotification userInfo] objectForKey:@"NSWorkspaceVolumeLocalizedNameKey"]], MGMNDescription, icon, MGMNIcon, nil]];
}
- (void)didMountDrive:(NSNotification *)theNotification {
	NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:[[theNotification userInfo] objectForKey:MGMNSDevicePath]];
	[[icon TIFFRepresentation] writeToFile:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]] atomically:NO];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"didmountvolume", MGMNName, @"Volume Mounted", MGMNTitle, [[theNotification userInfo] objectForKey:MGMNSWorkspaceVolumeLocalizedNameKey], MGMNDescription, icon, MGMNIcon, nil]];
}
- (void)willUnmountDrive:(NSNotification *)theNotification {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSImage *icon = nil;
	if ([manager fileExistsAtPath:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]]]) {
		icon = [[[NSImage alloc] initWithContentsOfFile:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]]] autorelease];
	} else {
		icon = [[NSWorkspace sharedWorkspace] iconForFile:[[theNotification userInfo] objectForKey:MGMNSDevicePath]];
		[[icon TIFFRepresentation] writeToFile:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]] atomically:NO];
	}
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"willunmountvolume", MGMNName, @"Volume Will Umount", MGMNTitle, [[theNotification userInfo] objectForKey:MGMNSWorkspaceVolumeLocalizedNameKey], MGMNDescription, icon, MGMNIcon, nil]];
}
- (void)didUnmountDrive:(NSNotification *)theNotification {
	NSFileManager *manager = [NSFileManager defaultManager];
	NSImage *icon = nil;
	if ([manager fileExistsAtPath:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]]]) {
		icon = [[[NSImage alloc] initWithContentsOfFile:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]]] autorelease];
		[manager removeItemAtPath:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]]];
	} else {
		icon = [[NSWorkspace sharedWorkspace] iconForFile:[[theNotification userInfo] objectForKey:MGMNSDevicePath]];
		[[icon TIFFRepresentation] writeToFile:[[MGMCachePath stringByExpandingTildeInPath] stringByAppendingPathComponent:[[[theNotification userInfo] objectForKey:MGMNSDevicePath] MD5]] atomically:NO];
	}
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"didunmountvolume", MGMNName, @"Volume Unmounted", MGMNTitle, [[theNotification userInfo] objectForKey:MGMNSWorkspaceVolumeLocalizedNameKey], MGMNDescription, icon, MGMNIcon, nil]];
}
@end