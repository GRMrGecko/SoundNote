//
//  MGMITunesWatcher.m
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

#import "MGMITunesWatcher.h"
#import "MGMController.h"
#import <EyeTunes/EyeTunes.h>

NSString * const MGMTName = @"Name";
NSString * const MGMTArtist = @"Artist";

@implementation MGMITunesWatcher
- (id)init {
	if ((self = [super init])) {
		NSDistributedNotificationCenter *notificationCenter = [NSDistributedNotificationCenter defaultCenter];
		[notificationCenter addObserver:self selector:@selector(itunesActivity:) name:@"com.apple.iTunes.playerInfo" object:nil];
		[notificationCenter addObserver:self selector:@selector(itunesSaved:) name:@"com.apple.iTunes.sourceSaved" object:nil];
	}
	return self;
}
- (void)dealloc {
	[[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void)itunesActivity:(NSNotification *)theNotification {
	NSString *playerState = [[theNotification userInfo] objectForKey:@"Player State"];
	ETTrack *currentTrack = [[EyeTunes sharedInstance] currentTrack];
	NSImage *image = nil;
	NSArray *artwork = [currentTrack artwork];
	if ([artwork count]>0)
		image = [artwork objectAtIndex:0];
	else
		image = [[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"]];
	
	NSString *trackName = @"";
	if ([[theNotification userInfo] objectForKey:MGMTName]!=nil && ![[[theNotification userInfo] objectForKey:MGMTName] isEqual:@""])
		trackName = [[theNotification userInfo] objectForKey:MGMTName];
	if ([[theNotification userInfo] objectForKey:MGMTArtist]!=nil && ![[[theNotification userInfo] objectForKey:MGMTArtist] isEqual:@""]) {
		trackName = [trackName stringByAppendingFormat:@" by %@", [[theNotification userInfo] objectForKey:MGMTArtist]];
	}
	if ([playerState isEqualToString:@"Playing"]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"itunesplaying", MGMNName, @"Now Playing", MGMNTitle, trackName, MGMNDescription, image, MGMNIcon, nil]];
	} else if ([playerState isEqualToString:@"Paused"]) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"itunespaused", MGMNName, @"Paused", MGMNTitle, trackName, MGMNDescription, image, MGMNIcon, nil]];
	} else {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"itunesstopped", MGMNName, @"Stopped", MGMNTitle, @"iTunes is no longer playing.", MGMNDescription, image, MGMNIcon, nil]];
	}
}
- (void)itunesSaved:(NSNotification *)theNotification {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"itunessaved", MGMNName, @"iTunes Saved", MGMNTitle, [NSString stringWithFormat:@"iTunes saved %@.", [[theNotification userInfo] objectForKey:MGMTName]], MGMNDescription, [[NSWorkspace sharedWorkspace] iconForFile:[[NSWorkspace sharedWorkspace] fullPathForApplication:@"iTunes"]], MGMNIcon, nil]];
	[pool drain];
}
@end