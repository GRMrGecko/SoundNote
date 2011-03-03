//
//  MGMNetworkWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

@interface MGMNetworkWatcher : NSObject {
	CFRunLoopSourceRef runLoop;
	SCDynamicStoreRef store;
	NSDictionary *lastAirPortState;
	
	NSString *lastMediaInfo;
	NSString *IPv4Addresses;
	NSString *IPv6Addresses;
	
	NSDate *lastCheck;
	
	NSURLConnection *connection;
	NSMutableData *data;
	NSURLConnection *connection2;
	NSMutableData *data2;
}
- (NSString *)getEthernetMedia;
- (void)ethernetLinkChanged:(NSDictionary *)theState;

- (void)ipv4Changed:(NSDictionary *)theInfo;
- (void)ipv6Changed:(NSDictionary *)theInfo;

- (void)airportChanged:(NSDictionary *)theInfo;
@end