//
//  MGMSound.h
//  SoundNote
//
//  Created by Mr. Gecko on 9/23/10.
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

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#else
#import <Cocoa/Cocoa.h>
#endif

@class MGMSound;

@protocol MGMSoundDelegate <NSObject>
- (void)soundDidFinishPlaying:(MGMSound *)theSound;
@end

@protocol NSSoundDelegate;

@interface MGMSound : NSObject
#if TARGET_OS_IPHONE
<AVAudioPlayerDelegate>
#else
<NSSoundDelegate>
#endif
{
#if TARGET_OS_IPHONE
	AVAudioPlayer *sound;
#else
	NSSound *sound;
#endif
	id<MGMSoundDelegate> delegate;
	
	BOOL loops;
}
- (id)initWithContentsOfFile:(NSString *)theFile;
- (id)initWithContentsOfURL:(NSURL *)theURL;
- (id)initWithData:(NSData *)theData;

- (void)setDelegate:(id)theDelegate;
- (id<MGMSoundDelegate>)delegate;

- (void)setLoops:(BOOL)shouldLoop;
- (BOOL)loops;

- (void)play;
- (void)pause;
- (void)stop;
- (BOOL)isPlaying;
@end