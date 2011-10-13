//
//  MGMFireWireWatcher.m
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

#import "MGMFireWireWatcher.h"
#import "MGMController.h"
#import <IOKit/IOKitLib.h>

char * const IOFireWireDevice = "IOFireWireDevice";

static void firewireConnected(void *refCon, io_iterator_t iterator) {
	io_object_t	object;
	while ((object = IOIteratorNext(iterator))) {
		[(MGMFireWireWatcher *)refCon firewireDeviceConnected:object];
		IOObjectRelease(object);
	}
}
static void firewireDisconnected(void *refCon, io_iterator_t iterator) {
	io_object_t	object;
	while ((object = IOIteratorNext(iterator))) {
		[(MGMFireWireWatcher *)refCon firewireDeviceDisconnected:object];
		IOObjectRelease(object);
	}
}

static NSString *nameForIOFW(io_object_t object) {
	io_name_t ioDeviceName;
	NSString *deviceName = nil;
	kern_return_t result = IORegistryEntryGetName(object, ioDeviceName);
	if (result==noErr)
		deviceName = [(NSString *)CFStringCreateWithCString(kCFAllocatorDefault, ioDeviceName, kCFStringEncodingUTF8) autorelease];
	if (deviceName!=nil)
		return deviceName;
	
	if (deviceName!=nil && ![deviceName isEqual:@"IOFireWireDevice"])
		return deviceName;
	
	deviceName = [(NSString *)IORegistryEntrySearchCFProperty(object, kIOFireWirePlane, (CFStringRef)@"FireWire Product Name", nil, kIORegistryIterateRecursively) autorelease];
	if (deviceName!=nil)
		return deviceName;
	
	deviceName = [(NSString *)IORegistryEntrySearchCFProperty(object, kIOFireWirePlane, (CFStringRef)@"FireWire Vendor Name", nil, kIORegistryIterateRecursively) autorelease];
	if (deviceName!=nil)
		return deviceName;
	
	return @"Unnamed Device";
}

@implementation MGMFireWireWatcher
- (id)init {
	if ((self = [super init])) {
		notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		runLoop = IONotificationPortGetRunLoopSource(notificationPort);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
		
		firewireDevices = [NSMutableArray new];
		
		CFDictionaryRef servicesMatch = IOServiceMatching(IOFireWireDevice);
		io_iterator_t found;
		kern_return_t result = IOServiceAddMatchingNotification(notificationPort, kIOPublishNotification, servicesMatch, firewireConnected, NULL, &found);
		if (result!=kIOReturnSuccess)
			NSLog(@"Unable to register for firewire add %d", result);
		io_object_t	object;
		while ((object = IOIteratorNext(found))) {
			NSString *deviceName = nameForIOFW(object);
			if (![firewireDevices containsObject:deviceName])
				[firewireDevices addObject:deviceName];
			IOObjectRelease(object);
		}
		
		servicesMatch = IOServiceMatching(IOFireWireDevice);
		result = IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, servicesMatch, firewireDisconnected, NULL, &found);
		if (result!=kIOReturnSuccess)
			NSLog(@"Unable to register for firewire remove %d", result);
		else {
			while ((object = IOIteratorNext(found))) {
				NSString *deviceName = nameForIOFW(object);
				if ([firewireDevices containsObject:deviceName])
					[firewireDevices removeObject:deviceName];
				IOObjectRelease(object);
			}
		}
	}
	return self;
}
- (void)dealloc {
	if (notificationPort) {
		CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
		IONotificationPortDestroy(notificationPort);
	}
	[firewireDevices release];
	[super dealloc];
}

- (void)firewireDeviceConnected:(io_object_t)theDevice {
	NSString *deviceName = nameForIOFW(theDevice);
	if (![firewireDevices containsObject:deviceName]) {
		[firewireDevices addObject:deviceName];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"firewireconnected", MGMNName, @"FireWire Connected", MGMNTitle, deviceName, MGMNDescription, [NSImage imageNamed:@"FireWire"], MGMNIcon, nil]];
	}
}
- (void)firewireDeviceDisconnected:(io_object_t)theDevice {
	NSString *deviceName = nameForIOFW(theDevice);
	if ([firewireDevices containsObject:deviceName]) {
		[firewireDevices removeObject:deviceName];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"firewiredisconnected", MGMNName, @"FireWire Disconnected", MGMNTitle, deviceName, MGMNDescription, [NSImage imageNamed:@"FireWire"], MGMNIcon, nil]];
	}
}
@end