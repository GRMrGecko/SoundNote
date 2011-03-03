//
//  MGMUSBWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>

@interface MGMUSBWatcher : NSObject {
	IONotificationPortRef notificationPort;
	CFRunLoopSourceRef runLoop;
	
	NSMutableArray *USBDevices;
}
- (void)usbDeviceConnected:(io_object_t)theDevice;
- (void)usbDeviceDisconnected:(io_object_t)theDevice;
@end