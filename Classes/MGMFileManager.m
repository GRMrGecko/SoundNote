#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
//
//  MGMFileManager.m
//  SoundNote
//
//  Created by Mr. Gecko on 1/22/11.
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

#import "MGMFileManager.h"

@implementation NSFileManager (MGMFileManager)
- (BOOL)moveItemAtPath:(NSString *)thePath toPath:(NSString *)theDestination {
	if ([self respondsToSelector:@selector(movePath:toPath:handler:)])
		return [self movePath:thePath toPath:theDestination handler:nil];
	else
		return [self moveItemAtPath:thePath toPath:theDestination error:nil];
}
- (BOOL)copyItemAtPath:(NSString *)thePath toPath:(NSString *)theDestination {
	if ([self respondsToSelector:@selector(copyPath:toPath:handler:)])
		return [self copyPath:thePath toPath:theDestination handler:nil];
	else
		return [self copyItemAtPath:thePath toPath:theDestination error:nil];
}
- (BOOL)removeItemAtPath:(NSString *)thePath {
	if ([self respondsToSelector:@selector(removeFileAtPath:handler:)])
		return [self removeFileAtPath:thePath handler:nil];
	else
		return [self removeItemAtPath:thePath error:nil];
}
- (BOOL)linkItemAtPath:(NSString *)thePath toPath:(NSString *)theDestination {
	if ([self respondsToSelector:@selector(linkPath:toPath:handler:)])
		return [self linkPath:thePath toPath:theDestination handler:nil];
	else
		return [self linkItemAtPath:thePath toPath:theDestination error:nil];
}
- (BOOL)createDirectoryAtPath:(NSString *)thePath withAttributes:(NSDictionary *)theAttributes {
	if ([self respondsToSelector:@selector(createDirectoryAtPath:attributes:)]) {
		BOOL isDirectory;
		if (![self fileExistsAtPath:thePath isDirectory:&isDirectory] && ![[thePath stringByDeletingLastPathComponent] isEqual:@""])
			[self createDirectoryAtPath:[thePath stringByDeletingLastPathComponent] withAttributes:nil];
		else if (!isDirectory || [[thePath stringByDeletingLastPathComponent] isEqual:@""])
			return false;
		return [self createDirectoryAtPath:thePath attributes:theAttributes];
	} else {
		return [self createDirectoryAtPath:thePath withIntermediateDirectories:YES attributes:theAttributes error:nil];
	}
	return false;
}
- (BOOL)createSymbolicLinkAtPath:(NSString *)thePath withDestinationPath:(NSString *)theDestination {
	if ([self respondsToSelector:@selector(createSymbolicLinkAtPath:pathContent:)])
		return [self createSymbolicLinkAtPath:thePath pathContent:theDestination];
	else
		return [self createSymbolicLinkAtPath:thePath withDestinationPath:theDestination error:nil];
}
- (NSString *)destinationOfSymbolicLinkAtPath:(NSString *)thePath {
	if ([self respondsToSelector:@selector(pathContentOfSymbolicLinkAtPath:)])
		return [self pathContentOfSymbolicLinkAtPath:thePath];
	else
		return [self destinationOfSymbolicLinkAtPath:thePath error:nil];
}
- (NSArray *)contentsOfDirectoryAtPath:(NSString *)thePath {
	if ([self respondsToSelector:@selector(directoryContentsAtPath:)])
		return [self directoryContentsAtPath:thePath];
	else
		return [self contentsOfDirectoryAtPath:thePath error:nil];
}
- (NSDictionary *)attributesOfFileSystemForPath:(NSString *)thePath {
	if ([self respondsToSelector:@selector(fileSystemAttributesAtPath:)])
		return [self fileSystemAttributesAtPath:thePath];
	else
		return [self attributesOfFileSystemForPath:thePath error:nil];
}
- (void)setAttributes:(NSDictionary *)theAttributes ofItemAtPath:(NSString *)thePath {
	if ([self respondsToSelector:@selector(changeFileAttributes:atPath:)])
		[self changeFileAttributes:theAttributes atPath:thePath];
	else
		[self setAttributes:theAttributes ofItemAtPath:thePath error:nil];
}
- (NSDictionary *)attributesOfItemAtPath:(NSString *)thePath {
	if ([self respondsToSelector:@selector(fileAttributesAtPath:traverseLink:)])
		return [self fileAttributesAtPath:thePath traverseLink:YES];
	else
		return [self attributesOfItemAtPath:thePath error:nil];
}
@end