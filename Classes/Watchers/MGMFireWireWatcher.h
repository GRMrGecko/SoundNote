//
//  MGMFireWireWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/15/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>

@interface MGMFireWireWatcher : NSObject {
	IONotificationPortRef notificationPort;
	CFRunLoopSourceRef runLoop;
	
	NSMutableArray *firewireDevices;
}
- (void)firewireDeviceConnected:(io_object_t)theDevice;
- (void)firewireDeviceDisconnected:(io_object_t)theDevice;
@end