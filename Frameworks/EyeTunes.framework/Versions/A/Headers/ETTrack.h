/* ETTrack.h -- iTunes Track Object */

/*
 
 EyeTunes.framework - Cocoa iTunes Interface
 http://www.liquidx.net/eyetunes/
 
 Copyright (c) 2005-2007, Alastair Tse <alastair@liquidx.net>
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 Redistributions in binary form must reproduce the above copyright notice, this
 list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 Neither the Alastair Tse nor the names of its contributors may
 be used to endorse or promote products derived from this software without 
 specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
*/

#import <Foundation/Foundation.h>
#import "ETAppleEventObject.h"

@interface ETTrack : ETAppleEventObject {
}

- (id) initWithDescriptor:(AEDesc *)desc;

- (NSString *)name;
- (NSString *)album;
- (NSString *)albumArtist;				// >=7.0
- (NSString *)artist;
- (int)bitrate;
- (int)bpm;
- (int)bookmark;						// >=6.0.2
- (BOOL)bookmarkable;					// >=6.0.2
- (NSString *)category;					// >=6.0.2
- (NSString *)comment;
- (BOOL)compilation;
- (NSString *)composer;
- (NSString *)description;				// >=6.0.2
- (int)databaseId;
- (NSDate *)dateAdded;
- (int)discCount;
- (int)discNumber;
- (int)duration;
- (BOOL)enabled;
- (NSString *)episodeId;				// >=7.0
- (int)episodeNumber;					// >=7.0
- (NSString *)eq;
- (int)finish;
- (BOOL)gapless;						// >=7.0
- (NSString *)genre;
- (NSString *)grouping;
- (NSString *)kind;
- (NSString *)location;
- (NSString *)longDescription;			// >=6.0.2
- (NSString *)lyrics;					// >=6.0.2
- (NSDate *)modificationDate;
- (long long int)persistentId;			// >=6.0
- (NSString *) persistentIdAsString;	// >=6.0
- (int)playedCount;
- (NSDate *)playedDate;
- (BOOL)podcast;
- (int)rating;
- (int)sampleRate;
- (int)seasonNumber;					// >=7.0
- (int)size;
- (NSString *)show;						// >=7.0
- (int)skippedCount;					// >=7.0
- (NSDate *)skippedDate;				// >=7.0
- (int)start;
- (NSString *)time;
- (int)trackCount;
- (int)trackNumber;
- (BOOL)unplayed;						// >=7.1
- (DescType)videoKind;					// >=7.0
- (int)volumeAdjustment;
- (int)year;

- (void)setName:(NSString *)newValue;
- (void)setAlbum:(NSString *)newValue;
- (void)setArtist:(NSString *)newValue;
- (void)setAlbumArtist:(NSString *)newValue;	// >=7.0
- (void)setBookmark:(int)newValueSeconds;		// >=6.0.2
- (void)setBookmarkable:(BOOL)newValue;			// >=6.0.2
- (void)setBpm:(int)newValue;
- (void)setCategory:(NSString *)newValue;		// >=6.0.2
- (void)setComment:(NSString *)newValue;
- (void)setCompilation:(BOOL)newValue;
- (void)setComposer:(NSString *)newValue;
- (void)setDescription:(NSString *)newValue;	// >=6.0.2
- (void)setDiscCount:(int)newValue;
- (void)setDiscNumber:(int)newValue;
- (void)setEnabled:(BOOL)newValue;
- (void)setEpisodeId:(NSString *)newValue;		// >=7.0
- (void)setEpisodeNumber:(int)newValue;			// >=7.0
- (void)setEq:(NSString *)newValue;
- (void)setFinish:(int)newValueSeconds;
- (void)setGapless:(BOOL)newValue;				// >=7.0
- (void)setGenre:(NSString *)newValue;
- (void)setGrouping:(NSString *)newValue;
- (void)setLongDescription:(NSString *)newValue;// >=6.0.1
- (void)setLyrics:(NSString *)newValue;			// >=6.0.1
- (void)setPlayedCount:(int)newValue;
- (void)setPlayedDate:(NSDate *)newValue;
- (void)setRating:(int)newValue;
- (void)setSeasonNumber:(int)newValue;			// >=7.0
- (void)setSkippedCount:(int)newValue;			// >=7.0
- (void)setSkippedDate:(NSDate *)newValue;		// >=7.0
- (void)setStart:(int)newValue;
- (void)setTrackCount:(int)newValue;
- (void)setTrackNumber:(int)newValue;
- (void)setUnplayed:(BOOL)newValue;				// >=7.1
- (void)setVideoKind:(DescType)newValue;		// >=7.0
- (void)setVolumeAdjustment:(int)newValue;

- (void)setYear:(int)newValue;

- (NSArray *)artwork;
- (void)setArtwork:(NSArray *)newArtworks;
- (BOOL)setArtwork:(NSImage *)artwork atIndex:(int)index;


@end
