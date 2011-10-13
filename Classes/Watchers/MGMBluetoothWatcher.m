//
//  MGMBluetoothWatcher.m
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

#import "MGMBluetoothWatcher.h"
#import "MGMController.h"

static BOOL loadingBlueTooth;

static void bluetoothDisconnected(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothDeviceRef objectRef) {
	[(MGMBluetoothWatcher *)userRefCon bluetoohDeviceDisconnected:objectRef];
	[(MGMBluetoothWatcher *)userRefCon removeNotification:inRef];
	IOBluetoothUserNotificationUnregister(inRef);
}
static void bluetoothConnected(void *userRefCon, IOBluetoothUserNotificationRef inRef, IOBluetoothDeviceRef objectRef) {
	if (!loadingBlueTooth)
		[(MGMBluetoothWatcher *)userRefCon bluetoohDeviceConnected:objectRef];
	[(MGMBluetoothWatcher *)userRefCon addNotification:IOBluetoothDeviceRegisterForDisconnectNotification(objectRef, bluetoothDisconnected, userRefCon)];
}

@implementation MGMBluetoothWatcher
- (id)init {
	if ((self = [super init])) {
		loadingBlueTooth = YES;
		bluetoothNotification = IOBluetoothRegisterForDeviceConnectNotifications(bluetoothConnected, self);
		loadingBlueTooth = NO;
	}
	return self;
}
- (void)dealloc {
	IOBluetoothUserNotificationUnregister(bluetoothNotification);
	for (int i=0; i<[notifications count]; i++) {
		IOBluetoothUserNotificationUnregister([[notifications objectAtIndex:i] pointerValue]);
	}
	[notifications release];
	[super dealloc];
}

- (void)addNotification:(IOBluetoothUserNotificationRef)theNotification {
	[notifications addObject:(id)theNotification];
}
- (void)removeNotification:(IOBluetoothUserNotificationRef)theNotification {
	[notifications removeObject:(id)theNotification];
}

- (void)bluetoohDeviceConnected:(IOBluetoothDeviceRef)theDevice {
	IOBluetoothDevice *device = [IOBluetoothDevice withDeviceRef:theDevice];
	NSString *name = @"";
	if ([device respondsToSelector:@selector(getNameOrAddress)])
		name = [device getNameOrAddress];
	else
		name = [device nameOrAddress];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bluetoothconnected", MGMNName, @"Bluetooth Connected", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"Bluetooth"], MGMNIcon, nil]];
}
- (void)bluetoohDeviceDisconnected:(IOBluetoothDeviceRef)theDevice {
	IOBluetoothDevice *device = [IOBluetoothDevice withDeviceRef:theDevice];
	NSString *name = @"";
	if ([device respondsToSelector:@selector(getNameOrAddress)])
		name = [device getNameOrAddress];
	else
		name = [device nameOrAddress];
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"bluetoothdisconnected", MGMNName, @"Bluetooth Disconnected", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"Bluetooth"], MGMNIcon, nil]];
}
@end