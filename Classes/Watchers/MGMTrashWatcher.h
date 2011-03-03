//
//  MGMTrashWatcher.h
//  SoundNote
//
//  Created by Mr. Gecko on 2/17/11.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Foundation/Foundation.h>

@class MGMPathSubscriber;

@interface MGMTrashWatcher : NSObject {
	MGMPathSubscriber *trashWatcher;
	int lastCount;
}

@end