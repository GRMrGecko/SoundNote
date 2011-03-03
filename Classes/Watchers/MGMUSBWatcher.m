//
//  MGMUSBWatcher.m
//  SoundNote
//
//  Created by Mr. Gecko on 2/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import "MGMUSBWatcher.h"
#import "MGMController.h"
#import <IOKit/IOKitLib.h>

char * const IOUSBDevice = "IOUSBDevice";

static void usbConnected(void *refCon, io_iterator_t iterator) {
	io_object_t	object;
	while ((object = IOIteratorNext(iterator))) {
		[(MGMUSBWatcher *)refCon usbDeviceConnected:object];
		IOObjectRelease(object);
	}
}
static void usbDisconnected(void *refCon, io_iterator_t iterator) {
	io_object_t	object;
	while ((object = IOIteratorNext(iterator))) {
		[(MGMUSBWatcher *)refCon usbDeviceDisconnected:object];
		IOObjectRelease(object);
	}
}

static NSString *nameForIOUSB(io_object_t object) {
	io_name_t ioDeviceName;
	NSString *deviceName = nil;
	kern_return_t result = IORegistryEntryGetName(object, ioDeviceName);
	if (result==noErr)
		deviceName = [(NSString *)CFStringCreateWithCString(kCFAllocatorDefault, ioDeviceName, kCFStringEncodingUTF8) autorelease];
	if (deviceName!=nil)
		return deviceName;
	
	return @"Unnamed Device";
}
static NSString *idForIOUSB(io_object_t object) {
	uint64_t ioDeviceID;
	NSString *deviceID = nil;
	kern_return_t result = IORegistryEntryGetRegistryEntryID(object, &ioDeviceID);
	if (result==noErr)
		deviceID = [NSString stringWithFormat:@"%11x", ioDeviceID];
	if (deviceID!=nil)
		return deviceID;
	
	return @"Unknown ID";
}

@implementation MGMUSBWatcher
- (id)init {
	if ((self = [super init])) {
		notificationPort = IONotificationPortCreate(kIOMasterPortDefault);
		runLoop = IONotificationPortGetRunLoopSource(notificationPort);
		CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
		
		USBDevices = [NSMutableArray new];
		
		CFDictionaryRef servicesMatch = IOServiceMatching(IOUSBDevice);
		io_iterator_t found;
		kern_return_t result = IOServiceAddMatchingNotification(notificationPort, kIOPublishNotification, servicesMatch, usbConnected, self, &found);
		if (result!=kIOReturnSuccess)
			NSLog(@"Unable to register for usb add %d", result);
		io_object_t	object;
		while ((object = IOIteratorNext(found))) {
			NSString *deviceID = idForIOUSB(object);
			if (![USBDevices containsObject:deviceID])
				[USBDevices addObject:deviceID];
			IOObjectRelease(object);
		}
		
		servicesMatch = IOServiceMatching(IOUSBDevice);
		result = IOServiceAddMatchingNotification(notificationPort, kIOTerminatedNotification, servicesMatch, usbDisconnected, self, &found);
		if (result!=kIOReturnSuccess)
			NSLog(@"Unable to register for usb remove %d", result);
		else {
			while ((object = IOIteratorNext(found))) {
				NSString *deviceID = idForIOUSB(object);
				if ([USBDevices containsObject:deviceID])
					[USBDevices removeObject:deviceID];
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
	[USBDevices release];
	[super dealloc];
}

- (void)usbDeviceConnected:(io_object_t)theDevice {
	NSString *deviceID = idForIOUSB(theDevice);
	if (![USBDevices containsObject:deviceID]) {
		[USBDevices addObject:deviceID];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"usbconnected", MGMNName, @"USB Connected", MGMNTitle, nameForIOUSB(theDevice), MGMNDescription, [NSImage imageNamed:@"USB"], MGMNIcon, nil]];
	}
}
- (void)usbDeviceDisconnected:(io_object_t)theDevice {
	NSString *deviceID = idForIOUSB(theDevice);
	if ([USBDevices containsObject:deviceID]) {
		[USBDevices removeObject:deviceID];
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"usbdisconnected", MGMNName, @"USB Disconnected", MGMNTitle, nameForIOUSB(theDevice), MGMNDescription, [NSImage imageNamed:@"USB"], MGMNIcon, nil]];
	}
}
@end