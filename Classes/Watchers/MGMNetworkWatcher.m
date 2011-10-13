//
//  MGMNetworkWatcher.m
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

#import "MGMNetworkWatcher.h"
#import "MGMController.h"
#import <sys/socket.h>
#import <sys/sockio.h>
#import <sys/ioctl.h>
#import <net/if.h>
#import <net/if_media.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>

NSString * const MGMPrimaryInterface = @"PrimaryInterface";
NSString * const MGMAddresses = @"Addresses";
NSString * const MGMBSSID = @"BSSID";
NSString * const MGMSSID = @"SSID_STR";
NSString * const MGMCHANNEL = @"CHANNEL";

NSString * const MGMIPv4Info = @"State:/Network/Interface/%@/IPv4";
NSString * const MGMIPv6Info = @"State:/Network/Interface/%@/IPv6";
NSString * const MGMEthernetLink = @"State:/Network/Interface/en0/Link";
NSString * const MGMIPv4State = @"State:/Network/Global/IPv4";
NSString * const MGMIPv6State = @"State:/Network/Global/IPv6";
NSString * const MGMAirPortInfo = @"State:/Network/Interface/en1/AirPort";

static struct ifmedia_description ifm_subtype_ethernet_descriptions[] = IFM_SUBTYPE_ETHERNET_DESCRIPTIONS;
static struct ifmedia_description ifm_shared_option_descriptions[] = IFM_SHARED_OPTION_DESCRIPTIONS;

static void systemNotification(SCDynamicStoreRef store, NSArray *changedKeys, void *info) {
	for (int i=0; i<[changedKeys count]; ++i) {
		NSString *key = [changedKeys objectAtIndex:i];
		if ([key isEqual:MGMEthernetLink]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMNetworkWatcher *)info ethernetLinkChanged:value];
			[value release];
		} else if ([key isEqual:MGMIPv4State]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMNetworkWatcher *)info ipv4Changed:value];
			[value release];
		} else if ([key isEqual:MGMIPv6State]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMNetworkWatcher *)info ipv6Changed:value];
			[value release];
		} else if ([key isEqual:MGMAirPortInfo]) {
			NSDictionary *value = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)key);
			[(MGMNetworkWatcher *)info airportChanged:value];
			[value release];
		}
	}
}

@implementation MGMNetworkWatcher
- (id)init {
	if ((self = [super init])) {
		SCDynamicStoreContext context = {0, self, NULL, NULL, NULL};
		store = SCDynamicStoreCreate(kCFAllocatorDefault, CFBundleGetIdentifier(CFBundleGetMainBundle()), (SCDynamicStoreCallBack)systemNotification, &context);
		if (!store) {
			NSLog(@"Unable to create store for system configuration %s", SCErrorString(SCError()));
		} else {
			NSArray *keys = [NSArray arrayWithObjects:MGMEthernetLink, MGMIPv4State, MGMIPv6State, MGMAirPortInfo, nil];
			if (!SCDynamicStoreSetNotificationKeys(store, (CFArrayRef)keys, NULL)) {
				NSLog(@"faild to set the store for notifications %s", SCErrorString(SCError()));
				CFRelease(store);
				store = NULL;
			} else {
				runLoop = SCDynamicStoreCreateRunLoopSource(kCFAllocatorDefault, store, 0);
				CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
				
				[lastMediaInfo release];
				lastMediaInfo = [[self getEthernetMedia] retain];		
				
				NSDictionary *IPv4State = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)MGMIPv4State);
				NSDictionary *IPv4Info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv4Info, [IPv4State objectForKey:MGMPrimaryInterface]]);
				NSArray *addressesArray = [IPv4Info objectForKey:MGMAddresses];
				if ([addressesArray count]>0) {
					NSMutableString *addresses = [NSMutableString string];
					for (int i=0; i<[addressesArray count]; i++) {
						if (![addresses isEqual:@""])
							[addresses appendString:@"\n"];
						[addresses appendString:[addressesArray objectAtIndex:i]];
					}
					IPv4Addresses = [addresses retain];
				}
				[IPv4Info release];
				[IPv4State release];
				
				NSDictionary *IPv6State = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)MGMIPv6State);
				NSDictionary *IPv6Info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv6Info, [IPv6State objectForKey:MGMPrimaryInterface]]);
				addressesArray = [IPv6Info objectForKey:MGMAddresses];
				if ([addressesArray count]>0) {
					NSMutableString *addresses = [NSMutableString string];
					for (int i=0; i<[addressesArray count]; i++) {
						if (![addresses isEqual:@""])
							[addresses appendString:@"\n"];
						[addresses appendString:[addressesArray objectAtIndex:i]];
					}
					IPv6Addresses = [addresses retain];
				}
				[IPv6Info release];
				[IPv6State release];
				
				lastAirPortState = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)MGMAirPortInfo);
			}
		}
	}
	return self;
}
- (void)dealloc {
	if (store!=NULL) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
		CFRelease(store);
	}
	[lastAirPortState release];
	[super dealloc];
}

- (NSString *)getEthernetMedia {
	int testSocket = socket(AF_INET, SOCK_DGRAM, 0);
	if (testSocket<0) {
		NSLog(@"Can't open datagram socket");
		return NULL;
	}
	struct ifmediareq mediaRequest;
	memset(&mediaRequest, 0, sizeof(mediaRequest));
	strncpy(mediaRequest.ifm_name, "en0", sizeof(mediaRequest.ifm_name));
	
	if (ioctl(testSocket, SIOCGIFMEDIA, (caddr_t)&mediaRequest) < 0) {
		close(testSocket);
		return NULL;
	}
	close(testSocket);
	
	const char *type = "Unknown";
	struct ifmedia_description *description;
	for (description = ifm_subtype_ethernet_descriptions; description->ifmt_string; description++) {
		if (IFM_SUBTYPE(mediaRequest.ifm_active) == description->ifmt_word) {
			type = description->ifmt_string;
			break;
		}
	}
	
	NSMutableString *options = [NSMutableString string];
	for (description = ifm_shared_option_descriptions; description->ifmt_string; description++) {
		if (mediaRequest.ifm_active & description->ifmt_word) {
			if (![options isEqual:@""])
				[options appendString:@","];
			[options appendString:[NSString stringWithUTF8String:description->ifmt_string]];
		}
	}
	
	if ([options isEqual:@""])
		return [NSString stringWithUTF8String:type];
	return [NSString stringWithFormat:@"%s <%@>", type, options];
}
- (void)ethernetLinkChanged:(NSDictionary *)theState {
	if ([[theState objectForKey:@"Active"] boolValue]) {
		[lastMediaInfo release];
		lastMediaInfo = [[self getEthernetMedia] retain];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ethernetconnected", MGMNName, @"Ethernet Connected", MGMNTitle, lastMediaInfo, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
	} else{
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ethernetdisconnected", MGMNName, @"Ethernet Disconnected", MGMNTitle, lastMediaInfo, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
	}
}

- (void)checkIPAddresses {
	if (lastCheck!=nil && [lastCheck earlierDate:[NSDate dateWithTimeIntervalSinceNow:-2]]==lastCheck)
		return;
	[lastCheck release];
	lastCheck = [NSDate new];
	
	[connection cancel];
	[connection release];
	[data release];
	data = [NSMutableData new];
	connection = [[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://ipv4.mrgeckosmedia.net/ip.php"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5] delegate:self] retain];
	[connection2 cancel];
	[connection2 release];
	[data2 release];
	data2 = [NSMutableData new];
	connection2 = [[NSURLConnection connectionWithRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://ipv6.mrgeckosmedia.net/ip.php"] cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:5] delegate:self] retain];
}
- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)theError {
	NSLog(@"%@", theError);
}
- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSHTTPURLResponse *)theResponse {
	if (![[[theResponse MIMEType] lowercaseString] isEqual:@"text/plain"]) {
		if (theConnection==connection) {
			[connection cancel];
			[connection release];
			connection = nil;
			[data release];
			data = nil;
		} else if (theConnection==connection2) {
			[connection2 cancel];
			[connection2 release];
			connection2 = nil;
			[data2 release];
			data2 = nil;
		}
	}
}
- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData *)theData {
	if (theConnection==connection)
		[data appendData:theData];
	else if (theConnection==connection2)
		[data2 appendData:theData];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection {
	if (theConnection==connection) {
		NSString *ip = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ipv4address", MGMNName, @"External IPv4 Address", MGMNTitle, ip, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
		[data release];
		data = nil;
		[connection release];
		connection = nil;
	} else if (theConnection==connection2) {
		NSString *ip = [[[NSString alloc] initWithData:data2 encoding:NSUTF8StringEncoding] autorelease];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ipv6address", MGMNName, @"External IPv6 Address", MGMNTitle, ip, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
		[data2 release];
		data2 = nil;
		[connection2 release];
		connection2 = nil;
	}
}

- (void)ipv4Changed:(NSDictionary *)theInfo {
	NSDictionary *info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv4Info, [theInfo objectForKey:MGMPrimaryInterface]]);
	NSArray *addressesArray = [info objectForKey:MGMAddresses];
	if ([addressesArray count]>0) {
		NSMutableString *addresses = [NSMutableString string];
		for (int i=0; i<[addressesArray count]; i++) {
			if (![addresses isEqual:@""])
				[addresses appendString:@"\n"];
			[addresses appendString:[addressesArray objectAtIndex:i]];
		}
		[IPv4Addresses release];
		IPv4Addresses = [addresses retain];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ipv4acquired", MGMNName, @"IPv4 Acquired", MGMNTitle, addresses, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
		[self checkIPAddresses];
	} else {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ipv4released", MGMNName, @"IPv4 Released", MGMNTitle, IPv4Addresses, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
	}
	[info release];
}
- (void)ipv6Changed:(NSDictionary *)theInfo {
	NSDictionary *info = (NSDictionary *)SCDynamicStoreCopyValue(store, (CFStringRef)[NSString stringWithFormat:MGMIPv6Info, [theInfo objectForKey:MGMPrimaryInterface]]);
	NSArray *addressesArray = [info objectForKey:MGMAddresses];
	if ([addressesArray count]>0) {
		NSMutableString *addresses = [NSMutableString string];
		for (int i=0; i<[addressesArray count]; i++) {
			if (![addresses isEqual:@""])
				[addresses appendString:@"\n"];
			[addresses appendString:[addressesArray objectAtIndex:i]];
		}
		[IPv6Addresses release];
		IPv6Addresses = [addresses retain];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ipv6acquired", MGMNName, @"IPv6 Acquired", MGMNTitle, addresses, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
		[self checkIPAddresses];
	} else {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ipv6released", MGMNName, @"IPv6 Released", MGMNTitle, IPv6Addresses, MGMNDescription, [NSImage imageNamed:@"Ethernet"], MGMNIcon, nil]];
	}
	[info release];
}

- (void)airportChanged:(NSDictionary *)theInfo {
	if (theInfo!=nil && ![theInfo isEqual:lastAirPortState]) {
		NSData *BSSID = [theInfo objectForKey:MGMBSSID];
		if (![BSSID isEqual:[NSData dataWithBytes:"\x00" length:1]]) {
			NSNumber *linkStatus = [theInfo objectForKey:@"Link Status"];
			NSNumber *powerStatus = [theInfo objectForKey:@"Power Status"];
			if (linkStatus || powerStatus) {
				int status = 0;
				if (linkStatus) {
					status = [linkStatus intValue];
				} else if (powerStatus) {
					status = [powerStatus intValue];
					status = !status;
				}
				
				if ([BSSID isEqual:[lastAirPortState objectForKey:MGMBSSID]] && status!=1 && [[theInfo objectForKey:@"Busy"] boolValue])
					return;
				
				if (status==1) {
					NSString *SSID = [lastAirPortState objectForKey:MGMSSID];
					const unsigned char *BSSIDBytes = [[lastAirPortState objectForKey:MGMBSSID] bytes];
					NSString *BSSIDString = nil;
					if (BSSIDBytes!=NULL)
						BSSIDString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", BSSIDBytes[0], BSSIDBytes[1], BSSIDBytes[2], BSSIDBytes[3], BSSIDBytes[4], BSSIDBytes[5]];
					int channel = [[[lastAirPortState objectForKey:MGMCHANNEL] objectForKey:MGMCHANNEL] intValue];
					NSString *name = [NSString stringWithFormat:@"SSID: %@\nBSSID: %@\nChannel: %d", SSID, BSSIDString, channel];
					[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"airportdisconnected", MGMNName, @"AirPort Disconnected", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"AirPort"], MGMNIcon, nil]];
				} else {
					NSString *SSID = [theInfo objectForKey:MGMSSID];
					const unsigned char *BSSIDBytes = [BSSID bytes];
					NSString *BSSIDString = nil;
					if (BSSIDBytes!=NULL)
						BSSIDString = [NSString stringWithFormat:@"%02X:%02X:%02X:%02X:%02X:%02X", BSSIDBytes[0], BSSIDBytes[1], BSSIDBytes[2], BSSIDBytes[3], BSSIDBytes[4], BSSIDBytes[5]];
					int channel = [[[theInfo objectForKey:MGMCHANNEL] objectForKey:MGMCHANNEL] intValue];
					NSString *name = [NSString stringWithFormat:@"SSID: %@\nBSSID: %@\nChannel: %d", SSID, BSSIDString, channel];
					[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"airportconnected", MGMNName, @"AirPort Connected", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"AirPort"], MGMNIcon, nil]];
				}
				[lastAirPortState release];
				lastAirPortState = [theInfo retain];
			}
		}
	}
}
@end