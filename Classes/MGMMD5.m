//
//  MGMMD5.m
//
//  Created by Mr. Gecko <GRMrGecko@gmail.com> on 1/6/10.
//  No Copyright Claimed. Public Domain.
//  C Algorithm created by Colin Plumb
//

#ifdef __NEXT_RUNTIME__
#import "MGMMD5.h"
#import "MGMTypes.h"


NSString * const MDNMD5 = @"md5";

@implementation NSString (MGMMD5)
- (NSString *)MD5 {
	NSData *MDData = [self dataUsingEncoding:NSUTF8StringEncoding];
	struct MD5Context MDContext;
	unsigned char MDDigest[MD5Length];
	
	MD5Init(&MDContext);
	MD5Update(&MDContext, [MDData bytes], [MDData length]);
	MD5Final(MDDigest, &MDContext);
	
	char *stringBuffer = (char *)malloc(MD5Length * 2 + 1);
	char *hexBuffer = stringBuffer;
	
	for (int i=0; i<MD5Length; i++) {
		*hexBuffer++ = hexdigits[(MDDigest[i] >> 4) & 0xF];
		*hexBuffer++ = hexdigits[MDDigest[i] & 0xF];
	}
	*hexBuffer = '\0';
	NSString *hash = [NSString stringWithUTF8String:stringBuffer];
	free(stringBuffer);
	return hash;
}
- (NSString *)pathMD5 {
	NSFileHandle *file = [NSFileHandle fileHandleForReadingAtPath:self];
	if (file==nil)
		return nil;
	struct MD5Context MDContext;
	unsigned char MDDigest[MD5Length];
	
	MD5Init(&MDContext);
	int length;
	do {
		NSAutoreleasePool *pool = [NSAutoreleasePool new];
		NSData *MDData = [file readDataOfLength:MDFileReadLength];
		length = [MDData length];
		MD5Update(&MDContext, [MDData bytes], length);
		[pool release];
	} while (length>0);
	MD5Final(MDDigest, &MDContext);
	
	char *stringBuffer = (char *)malloc(MD5Length * 2 + 1);
	char *hexBuffer = stringBuffer;
	
	for (int i=0; i<MD5Length; i++) {
		*hexBuffer++ = hexdigits[(MDDigest[i] >> 4) & 0xF];
		*hexBuffer++ = hexdigits[MDDigest[i] & 0xF];
	}
	*hexBuffer = '\0';
	NSString *hash = [NSString stringWithUTF8String:stringBuffer];
	free(stringBuffer);
	return hash;
}
@end
#else
#include <stdio.h>
#include <string.h>
#include "MGMMD5.h"
#include "MGMTypes.h"
#endif

char *MD5String(const char *string, int length) {
	struct MD5Context MDContext;
	unsigned char MDDigest[MD5Length];
	
	MD5Init(&MDContext);
	MD5Update(&MDContext, (const unsigned char *)string, length);
	MD5Final(MDDigest, &MDContext);
	
	char *stringBuffer = (char *)malloc(MD5Length * 2 + 1);
	char *hexBuffer = stringBuffer;
	
	for (int i=0; i<MD5Length; i++) {
		*hexBuffer++ = hexdigits[(MDDigest[i] >> 4) & 0xF];
		*hexBuffer++ = hexdigits[MDDigest[i] & 0xF];
	}
	*hexBuffer = '\0';
	
	return stringBuffer;
}
char *MD5File(const char *path) {
	FILE *file = fopen(path, "r");
	if (file==NULL)
		return NULL;
	struct MD5Context MDContext;
	unsigned char MDDigest[MD5Length];
	
	MD5Init(&MDContext);
	int length;
	do {
		unsigned char MDData[MDFileReadLength];
		length = fread(&MDData, 1, MDFileReadLength, file);
		MD5Update(&MDContext, MDData, length);
	} while (length>0);
	MD5Final(MDDigest, &MDContext);
	
	fclose(file);
	
	char *stringBuffer = (char *)malloc(MD5Length * 2 + 1);
	char *hexBuffer = stringBuffer;
	
	for (int i=0; i<MD5Length; i++) {
		*hexBuffer++ = hexdigits[(MDDigest[i] >> 4) & 0xF];
		*hexBuffer++ = hexdigits[MDDigest[i] & 0xF];
	}
	*hexBuffer = '\0';
	
	return stringBuffer;
}

void MD5Init(struct MD5Context *context) {
	context->buf[0] = 0x67452301;
	context->buf[1] = 0xefcdab89;
	context->buf[2] = 0x98badcfe;
	context->buf[3] = 0x10325476;
	
	context->bits[0] = 0;
	context->bits[1] = 0;
}

void MD5Update(struct MD5Context *context, const unsigned char *buf, unsigned len) {
	uint32_t t;
	
	t = context->bits[0];
	if ((context->bits[0] = (t + ((uint32_t)len << 3))) < t)
		context->bits[1]++;
	context->bits[1] += len >> 29;
	
	t = (t >> 3) & 0x3f;
	
	if (t!=0) {
		unsigned char *p = context->in + t;
		
		t = 64-t;
		if (len < t) {
			memcpy(p, buf, len);
			return;
		}
		memcpy(p, buf, t);
		MD5Transform(context->buf, context->in);
		buf += t;
		len -= t;
	}
	
	while (len >= 64) {
		memcpy(context->in, buf, 64);
		MD5Transform(context->buf, context->in);
		buf += 64;
		len -= 64;
	}
	
	memcpy(context->in, buf, len);
}

void MD5Final(unsigned char digest[MD5Length], struct MD5Context *context) {
	unsigned count;
	unsigned char *p;
	
	count = (context->bits[0] >> 3) & 0x3F;
	
	p = context->in + count;
	*p++ = MDPadding[0];
	
	count = 64 - 1 - count;
	
	if (count < 8) {
		memset(p, MDPadding[1], count);
		MD5Transform(context->buf, context->in);
		
		memset(context->in, MDPadding[1], 56);
	} else {
		memset(p, MDPadding[1], count-8);
	}
	
	putu32l(context->bits[0], context->in + 56);
	putu32l(context->bits[1], context->in + 60);
	
	MD5Transform(context->buf, context->in);
	for (int i=0; i<4; i++)
		putu32l(context->buf[i], digest + (4 * i));
	
	memset(context, 0, sizeof(context));
}

/* #define MD5_F1(x, y, z) (x & y | ~x & z) */
#define MD5_F1(x, y, z) (z ^ (x & (y ^ z)))
#define MD5_F2(x, y, z) MD5_F1(z, x, y)
#define MD5_F3(x, y, z) (x ^ y ^ z)
#define MD5_F4(x, y, z) (y ^ (x | ~z))

#define MD5STEP(f, w, x, y, z, data, s) \
	( w += f(x, y, z) + data, w &= 0xffffffff, w = w<<s | w>>(32-s), w += x )

void MD5Transform(uint32_t buf[MD5BufferSize], const unsigned char inraw[64]) {
	uint32_t in[16];
	int i;
	
	for (i = 0; i < 16; ++i) {
		in[i] = getu32l(inraw+4*i);
	}
	
	uint32_t a = buf[0];
	uint32_t b = buf[1];
	uint32_t c = buf[2];
	uint32_t d = buf[3];
	
	// Round 1
	MD5STEP(MD5_F1, a, b, c, d, in[ 0]+0xd76aa478, 7);
	MD5STEP(MD5_F1, d, a, b, c, in[ 1]+0xe8c7b756, 12);
	MD5STEP(MD5_F1, c, d, a, b, in[ 2]+0x242070db, 17);
	MD5STEP(MD5_F1, b, c, d, a, in[ 3]+0xc1bdceee, 22);
	MD5STEP(MD5_F1, a, b, c, d, in[ 4]+0xf57c0faf, 7);
	MD5STEP(MD5_F1, d, a, b, c, in[ 5]+0x4787c62a, 12);
	MD5STEP(MD5_F1, c, d, a, b, in[ 6]+0xa8304613, 17);
	MD5STEP(MD5_F1, b, c, d, a, in[ 7]+0xfd469501, 22);
	MD5STEP(MD5_F1, a, b, c, d, in[ 8]+0x698098d8, 7);
	MD5STEP(MD5_F1, d, a, b, c, in[ 9]+0x8b44f7af, 12);
	MD5STEP(MD5_F1, c, d, a, b, in[10]+0xffff5bb1, 17);
	MD5STEP(MD5_F1, b, c, d, a, in[11]+0x895cd7be, 22);
	MD5STEP(MD5_F1, a, b, c, d, in[12]+0x6b901122, 7);
	MD5STEP(MD5_F1, d, a, b, c, in[13]+0xfd987193, 12);
	MD5STEP(MD5_F1, c, d, a, b, in[14]+0xa679438e, 17);
	MD5STEP(MD5_F1, b, c, d, a, in[15]+0x49b40821, 22);
		
	// Round 2
	MD5STEP(MD5_F2, a, b, c, d, in[ 1]+0xf61e2562, 5);
	MD5STEP(MD5_F2, d, a, b, c, in[ 6]+0xc040b340, 9);
	MD5STEP(MD5_F2, c, d, a, b, in[11]+0x265e5a51, 14);
	MD5STEP(MD5_F2, b, c, d, a, in[ 0]+0xe9b6c7aa, 20);
	MD5STEP(MD5_F2, a, b, c, d, in[ 5]+0xd62f105d, 5);
	MD5STEP(MD5_F2, d, a, b, c, in[10]+0x02441453, 9);
	MD5STEP(MD5_F2, c, d, a, b, in[15]+0xd8a1e681, 14);
	MD5STEP(MD5_F2, b, c, d, a, in[ 4]+0xe7d3fbc8, 20);
	MD5STEP(MD5_F2, a, b, c, d, in[ 9]+0x21e1cde6, 5);
	MD5STEP(MD5_F2, d, a, b, c, in[14]+0xc33707d6, 9);
	MD5STEP(MD5_F2, c, d, a, b, in[ 3]+0xf4d50d87, 14);
	MD5STEP(MD5_F2, b, c, d, a, in[ 8]+0x455a14ed, 20);
	MD5STEP(MD5_F2, a, b, c, d, in[13]+0xa9e3e905, 5);
	MD5STEP(MD5_F2, d, a, b, c, in[ 2]+0xfcefa3f8, 9);
	MD5STEP(MD5_F2, c, d, a, b, in[ 7]+0x676f02d9, 14);
	MD5STEP(MD5_F2, b, c, d, a, in[12]+0x8d2a4c8a, 20);
		
	// Round 3
	MD5STEP(MD5_F3, a, b, c, d, in[ 5]+0xfffa3942, 4);
	MD5STEP(MD5_F3, d, a, b, c, in[ 8]+0x8771f681, 11);
	MD5STEP(MD5_F3, c, d, a, b, in[11]+0x6d9d6122, 16);
	MD5STEP(MD5_F3, b, c, d, a, in[14]+0xfde5380c, 23);
	MD5STEP(MD5_F3, a, b, c, d, in[ 1]+0xa4beea44, 4);
	MD5STEP(MD5_F3, d, a, b, c, in[ 4]+0x4bdecfa9, 11);
	MD5STEP(MD5_F3, c, d, a, b, in[ 7]+0xf6bb4b60, 16);
	MD5STEP(MD5_F3, b, c, d, a, in[10]+0xbebfbc70, 23);
	MD5STEP(MD5_F3, a, b, c, d, in[13]+0x289b7ec6, 4);
	MD5STEP(MD5_F3, d, a, b, c, in[ 0]+0xeaa127fa, 11);
	MD5STEP(MD5_F3, c, d, a, b, in[ 3]+0xd4ef3085, 16);
	MD5STEP(MD5_F3, b, c, d, a, in[ 6]+0x04881d05, 23);
	MD5STEP(MD5_F3, a, b, c, d, in[ 9]+0xd9d4d039, 4);
	MD5STEP(MD5_F3, d, a, b, c, in[12]+0xe6db99e5, 11);
	MD5STEP(MD5_F3, c, d, a, b, in[15]+0x1fa27cf8, 16);
	MD5STEP(MD5_F3, b, c, d, a, in[ 2]+0xc4ac5665, 23);
		
	// Round 4
	MD5STEP(MD5_F4, a, b, c, d, in[ 0]+0xf4292244, 6);
	MD5STEP(MD5_F4, d, a, b, c, in[ 7]+0x432aff97, 10);
	MD5STEP(MD5_F4, c, d, a, b, in[14]+0xab9423a7, 15);
	MD5STEP(MD5_F4, b, c, d, a, in[ 5]+0xfc93a039, 21);
	MD5STEP(MD5_F4, a, b, c, d, in[12]+0x655b59c3, 6);
	MD5STEP(MD5_F4, d, a, b, c, in[ 3]+0x8f0ccc92, 10);
	MD5STEP(MD5_F4, c, d, a, b, in[10]+0xffeff47d, 15);
	MD5STEP(MD5_F4, b, c, d, a, in[ 1]+0x85845dd1, 21);
	MD5STEP(MD5_F4, a, b, c, d, in[ 8]+0x6fa87e4f, 6);
	MD5STEP(MD5_F4, d, a, b, c, in[15]+0xfe2ce6e0, 10);
	MD5STEP(MD5_F4, c, d, a, b, in[ 6]+0xa3014314, 15);
	MD5STEP(MD5_F4, b, c, d, a, in[13]+0x4e0811a1, 21);
	MD5STEP(MD5_F4, a, b, c, d, in[ 4]+0xf7537e82, 6);
	MD5STEP(MD5_F4, d, a, b, c, in[11]+0xbd3af235, 10);
	MD5STEP(MD5_F4, c, d, a, b, in[ 2]+0x2ad7d2bb, 15);
	MD5STEP(MD5_F4, b, c, d, a, in[ 9]+0xeb86d391, 21);
	
	buf[0] += a;
	buf[1] += b;
	buf[2] += c;
	buf[3] += d;
}