//
//  MGMLoginItems.h
//  SoundNote
//
//  Created by Mr. Gecko on 8/7/10.
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

#import <Cocoa/Cocoa.h>

extern NSString * const MGMLoginItemsPath;

@interface MGMLoginItems : NSObject {
	NSMutableDictionary *loginItems;
}
+ (id)items;
- (NSArray *)paths;
- (BOOL)selfExists;
- (BOOL)addSelf;
- (BOOL)removeSelf;
- (BOOL)exists:(NSString *)thePath;
- (BOOL)add:(NSString *)thePath;
- (BOOL)add:(NSString *)thePath hide:(BOOL)shouldHide;
- (BOOL)remove:(NSString *)thePath;
- (void)_save;
@end