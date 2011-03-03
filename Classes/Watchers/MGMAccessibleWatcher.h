//
//  MGMAccessibleWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/17/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>

@interface MGMAccessibleWatcher : NSObject {
	NSMutableDictionary *observers;
}
- (void)registerObserversFor:(NSDictionary *)application;

- (void)receivedNotification:(NSString *)theName process:(ProcessSerialNumber *)theProcess element:(AXUIElementRef)theElement;
@end