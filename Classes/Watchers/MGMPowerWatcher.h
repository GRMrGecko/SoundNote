//
//  MGMPowerWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/16/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>

@interface MGMPowerWatcher : NSObject {
	CFRunLoopSourceRef runLoop;
	BOOL batterWarned20;
	BOOL batterWarned10;
	BOOL batterWarned5;
}
- (void)powerSourceChanged:(int)theType;
- (void)powerChargingStateChanged:(BOOL)isCharging percentage:(int)thePercent;
- (void)powerTimeChanged:(int)theTime;
@end