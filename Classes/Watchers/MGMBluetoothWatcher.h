//
//  MGMBluetoothWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>

@interface MGMBluetoothWatcher : NSObject {
	IOBluetoothUserNotificationRef bluetoothNotification;
	NSMutableArray *notifications;
}
- (void)addNotification:(IOBluetoothUserNotificationRef)theNotification;
- (void)removeNotification:(IOBluetoothUserNotificationRef)theNotification;

- (void)bluetoohDeviceConnected:(IOBluetoothObjectRef)theDevice;
- (void)bluetoohDeviceDisconnected:(IOBluetoothObjectRef)theDevice;
@end