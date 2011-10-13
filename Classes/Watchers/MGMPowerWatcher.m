//
//  MGMPowerWatcher.m
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

#import "MGMPowerWatcher.h"
#import "MGMController.h"
#import <IOKit/IOKitLib.h>
#import <IOKit/ps/IOPSKeys.h>
#import <IOKit/ps/IOPowerSources.h>

static int lastPowerSource;
static BOOL lastChargingState;
static int lastBatteryTime;

static void powerNotification(void *context) {
	CFTypeRef powerInfo = IOPSCopyPowerSourcesInfo();
	NSArray *powerSources = (NSArray *)IOPSCopyPowerSourcesList(powerInfo);
	
	for (int i=0; i<[powerSources count]; ++i) {
		NSString *powerSource;
		NSDictionary *powerSourceInfo;
		int powerSourceType = -1;
		BOOL charging = NO;
		int batteryTime = -1;
		int percentage = 0;
		
		powerSource = [powerSources objectAtIndex:i];
		powerSourceInfo = (NSDictionary *)IOPSGetPowerSourceDescription(powerInfo, powerSource);
		
		if (![[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSIsPresentKey]] boolValue])
			continue;
		
		if ([[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSTransportTypeKey]] isEqual:[NSString stringWithUTF8String:kIOPSInternalType]]) {
			NSString *currentState = [powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSPowerSourceStateKey]];
			
			if ([currentState isEqual:[NSString stringWithUTF8String:kIOPSACPowerValue]])
				powerSourceType = 0;
			else if ([currentState isEqual:[NSString stringWithUTF8String:kIOPSBatteryPowerValue]])
				powerSourceType = 1;
			else
				powerSourceType = -1;
			
			charging = [[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSIsChargingKey]] boolValue];
			if (charging) {
				batteryTime = [[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSTimeToFullChargeKey]] intValue];
			} else {
				batteryTime = [[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSTimeToEmptyKey]] intValue];
			}
			
			float currentCapacity = [[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSCurrentCapacityKey]] floatValue];;
			float maxCapacity = [[powerSourceInfo objectForKey:[NSString stringWithUTF8String:kIOPSMaxCapacityKey]] floatValue];;
			percentage = roundf((currentCapacity/maxCapacity)*100.0);
		} else {
			powerSourceType = 2;
		}
		if (lastPowerSource!=powerSourceType) {
			[(MGMPowerWatcher *)context powerSourceChanged:powerSourceType];
			lastPowerSource = powerSourceType;
		}
		if (powerSourceType==0 && lastChargingState!=charging) {
			[(MGMPowerWatcher *)context powerChargingStateChanged:charging percentage:percentage];
			lastChargingState = charging;
		}
		if (batteryTime!=-1 && lastBatteryTime!=batteryTime) {
			[(MGMPowerWatcher *)context powerTimeChanged:batteryTime];
			lastBatteryTime = batteryTime;
		}
	}
	
	[powerSources release];
	CFRelease(powerInfo);
}

@implementation MGMPowerWatcher
- (id)init {
	if ((self = [super init])) {
		runLoop = IOPSNotificationCreateRunLoopSource(powerNotification, self);
		if (runLoop!=NULL)
			CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoop, kCFRunLoopDefaultMode);
		lastPowerSource = -1;
		lastBatteryTime = -1;
		batterWarned20 = NO;
		batterWarned10 = NO;
		batterWarned5 = NO;
	}
	return self;
}
- (void)dealloc {
	[super dealloc];
}

- (void)powerSourceChanged:(int)theType {
	NSString *name = (theType==0 ? @"Power Adapter" : (theType==1 ? @"Battery" : @"UPS"));
	[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"powersourcechanged", MGMNName, @"New Power Source", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:(theType==0 ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
	if (theType==0) {
		batterWarned20 = NO;
		batterWarned10 = NO;
		batterWarned5 = NO;
		lastBatteryTime = -1;
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"poweronac", MGMNName, @"Power Source", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"BatteryCharging"], MGMNIcon, nil]];
	} else if (theType==1) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"poweronbattery", MGMNName, @"Power Source", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"Battery"], MGMNIcon, nil]];
	} else if (theType==2) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"poweronups", MGMNName, @"Power Source", MGMNTitle, name, MGMNDescription, [NSImage imageNamed:@"Battery"], MGMNIcon, nil]];
	}
}
- (void)powerChargingStateChanged:(BOOL)isCharging percentage:(int)thePercent {
	if (isCharging) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"charging", MGMNName, @"Charging", MGMNTitle, [NSString stringWithFormat:@"%d%%", thePercent], MGMNDescription, [NSImage imageNamed:(isCharging ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
	} else {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"charged", MGMNName, @"Charged", MGMNTitle, [NSString stringWithFormat:@"%d%%", thePercent], MGMNDescription, [NSImage imageNamed:(isCharging ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
	}
}
- (void)powerTimeChanged:(int)theTime {
	if (lastBatteryTime==-1) {
		[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"batterytime", MGMNName, @"Battery Charging", MGMNTitle, [NSString stringWithFormat:@"There is %d minutes remaining.", theTime], MGMNDescription, [NSImage imageNamed:(lastChargingState ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
	}
	if (lastPowerSource!=0) {
		if (theTime<=20 && theTime>10 && !batterWarned20) {
			batterWarned20 = YES;
			[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"battery20minutes", MGMNName, @"Battery Warning", MGMNTitle, @"There is 20 minutes remaining.", MGMNDescription, [NSImage imageNamed:(lastChargingState ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
		} else if (theTime<=10 && theTime>5 && !batterWarned10) {
			batterWarned10 = YES;
			[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"battery10minutes", MGMNName, @"Battery Warning", MGMNTitle, @"There is 10 minutes remaining.", MGMNDescription, [NSImage imageNamed:(lastChargingState ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
		} else if (theTime<=5 && !batterWarned5) {
			batterWarned5 = YES;
			[[MGMController sharedController] startNotificationWithInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"battery5minutes", MGMNName, @"Battery Warning", MGMNTitle, @"There is 5 minutes remaining.", MGMNDescription, [NSImage imageNamed:(lastChargingState ? @"BatteryCharging" : @"Battery")], MGMNIcon, nil]];
		}
	}
}
@end