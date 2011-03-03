//
//  MGMController.h
//  SoundNote
//
//  Created by Mr. Gecko on 7/4/10.
//  Copyright (c) 2011 Mr. Gecko's Media (James Coleman). All rights reserved. http://mrgeckosmedia.com/
//

#import <Cocoa/Cocoa.h>

extern NSString * const MGMApplicationSupportPath;

extern NSString * const MGMSoundEndedNotification;

extern NSString * const MGMNName;
extern NSString * const MGMNTitle;
extern NSString * const MGMNDescription;
extern NSString * const MGMNIcon;
extern NSString * const MGMNSound;
extern NSString * const MGMNTask;

@protocol NSWindowDelegate;

@interface MGMController : NSObject <NSWindowDelegate> {
	NSWindow *instructions;
	
	NSMutableArray *watchers;
	NSMutableArray *notifications;
	
	NSTimer *wakeTimer;
	BOOL ignoreNotifications;
	NSDate *lastUpdated;
	NSDictionary *growl;
}
+ (id)sharedController;
- (void)showInstructions;

- (void)registerDefaults;
- (IBAction)donate:(id)sender;

- (void)registerWatcher:(id)theWatcher;
- (NSMutableDictionary *)startNotificationWithInfo:(NSDictionary *)theInfo;
- (NSMutableDictionary *)notificationWithName:(NSString *)theName;

- (IBAction)Quit:(id)sender;
@end