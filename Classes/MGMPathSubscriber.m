//
//  MGMPathSubscriber.m
//  SoundNote
//
//  Created by Mr. Gecko on 1/15/11.
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

#import "MGMPathSubscriber.h"

@interface MGMPathSubscriber (MGMPrivate)
- (void)subscriptionChanged:(FNSubscriptionRef)theSubscription;
- (void)sendNotificationForPath:(NSString *)thePath;
@end

static MGMPathSubscriber *MGMSharedPathSubscriber;
NSString * const MGMSubscribedPathChangedNotification = @"MGMSubscribedPathChangedNotification";

void MGMPathSubscriptionChange(FNMessage theMessage, OptionBits theFlags, void *thePathSubscription, FNSubscriptionRef theSubscription) {
    if (theMessage==kFNDirectoryModifiedMessage)
        [(MGMPathSubscriber *)thePathSubscription subscriptionChanged:theSubscription];
	else
		NSLog(@"MGMPathSubscription: Received Unknown message: %d", (int)theMessage);
}

@implementation MGMPathSubscriber
+ (id)sharedPathSubscriber {
	if (MGMSharedPathSubscriber==nil)
		MGMSharedPathSubscriber = [MGMPathSubscriber new];
	return MGMSharedPathSubscriber;
}
- (id)init {
	if ((self = [super init])) {
		subscriptions = [NSMutableDictionary new];
		subscriptionUPP = NewFNSubscriptionUPP(MGMPathSubscriptionChange);
		notificationsSending = [NSMutableArray new];
	}
	return self;
}
- (void)dealloc {
	[self removeAllPaths];
	DisposeFNSubscriptionUPP(subscriptionUPP);
	[subscriptions release];
	[notificationsSending release];
	[super dealloc];
}

- (id<MGMPathSubscriberDelegate>)delegate {
	return delegate;
}
- (void)setDelegate:(id)theDelegate {
	delegate = theDelegate;
}

- (void)addPath:(NSString *)thePath {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil)
		return;
	FNSubscriptionRef subscription = NULL;
	OSStatus error = FNSubscribeByPath((UInt8 *)[thePath fileSystemRepresentation], subscriptionUPP, self, kFNNotifyInBackground, &subscription);
	if (error!=noErr) {
		NSLog(@"MGMPathSubscription: Unable to subscribe to %@ due to the error %ld", thePath, (long)error);
		return;
	}
	[subscriptions setObject:[NSValue valueWithPointer:subscription] forKey:thePath];
}
- (void)removePath:(NSString *)thePath {
	NSValue *value = [subscriptions objectForKey:thePath];
	if (value!=nil) {
		FNUnsubscribe([value pointerValue]);
		[subscriptions removeObjectForKey:thePath];
	}
}
- (void)removeAllPaths {
	NSArray *keys = [subscriptions allKeys];
	for (int i=0; i<[keys count]; i++) {
		FNUnsubscribe([[subscriptions objectForKey:[keys objectAtIndex:i]] pointerValue]);
	}
	[subscriptions removeAllObjects];
}

- (NSArray *)subscribedPaths {
	return [subscriptions allKeys];
}

- (void)subscriptionChanged:(FNSubscriptionRef)theSubscription {
	NSArray *keys = [subscriptions allKeysForObject:[NSValue valueWithPointer:theSubscription]];
	if ([keys count]>=1) {
		NSString *path = [keys objectAtIndex:0];
		if (![notificationsSending containsObject:path]) {
			[notificationsSending addObject:path];
			[self performSelector:@selector(sendNotificationForPath:) withObject:path afterDelay:0.5];
		}
	}
}
- (void)sendNotificationForPath:(NSString *)thePath {
	[[NSNotificationCenter defaultCenter] postNotificationName:MGMSubscribedPathChangedNotification object:thePath];
	if ([delegate respondsToSelector:@selector(subscribedPathChanged:)]) [delegate subscribedPathChanged:thePath];
	[notificationsSending removeObject:thePath];
}
@end