//
// FreeOTP
//
// Authors: Nathaniel McCallum <npmccallum@redhat.com>
//
// Copyright (C) 2013  Nathaniel McCallum, Red Hat
// see file 'COPYING' for use and warranty information
//
// This program is free software you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "Token.h"
#import <CommonCrypto/CommonHMAC.h>
#import "base32.h"
#import <sys/time.h>
static NSString* decode(const NSString* str) {
    if (str == nil)
        return nil;
    
    str = [str stringByReplacingOccurrencesOfString:@"+" withString:@" "];
    return [str stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
static NSString* encode(const NSString* str) {
    if (str == nil)
        return nil;
    str = [str stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    return [str stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}
static NSData* parseKey(const NSString *secret) {
    uint8_t key[4096];
    if (secret == nil)
        return nil;
    const char *tmp = [secret cStringUsingEncoding:NSASCIIStringEncoding];
    if (tmp == NULL)
        return nil;
    
    int res = base32_decode(tmp, key, sizeof(key));
    if (res < 0 || res == sizeof(key))
        return nil;
    
    return [NSData dataWithBytes:key length:res];
}

static CCHmacAlgorithm parseAlgo(const NSString* algo) {
    static struct {
        const char *name;
        CCHmacAlgorithm num;
    } algomap[] = {
        { "md5", kCCHmacAlgMD5 },
        { "sha1", kCCHmacAlgSHA1 },
        { "sha256", kCCHmacAlgSHA256 },
        { "sha512", kCCHmacAlgSHA512 },
    };
    if (algo == nil)
        return kCCHmacAlgSHA1;
    
    const char *calgo = [algo cStringUsingEncoding:NSUTF8StringEncoding];
    if (calgo == NULL)
        return kCCHmacAlgSHA1;
    for (int i = 0; i < sizeof(algomap) / sizeof(algomap[0]); i++) {
        if (strcasecmp(calgo, algomap[i].name) == 0)
            return algomap[i].num;
    }
    
    return kCCHmacAlgSHA1;
}

static NSInteger parseDigits(const NSString* digits) {
    if (digits == nil)
        return 6;
    
    NSInteger val = [digits integerValue];
    if (val != 6 && val != 8)
        return 6;
    
    return val;
}

static inline const char* unparseAlgo(CCHmacAlgorithm algo) {
    switch (algo) {
        case kCCHmacAlgMD5:
            return "md5";
        case kCCHmacAlgSHA256:
            return "sha256";
        case kCCHmacAlgSHA512:
            return "sha512";
        case kCCHmacAlgSHA1:
        default:
            return "sha1";
    }
}

static NSString* unparseKey(const NSData* key) {
    char buf[8192];
    
    int res = base32_encode([key bytes], (int) [key length], buf, sizeof(buf));
    if (res < 0 || res >= sizeof(buf))
        return nil;
    
    return [NSString stringWithUTF8String:buf];
}

static inline size_t getDigestLength(CCHmacAlgorithm algo) {
    switch (algo) {
        case kCCHmacAlgMD5:
            return CC_MD5_DIGEST_LENGTH;
        case kCCHmacAlgSHA256:
            return CC_SHA256_DIGEST_LENGTH;
        case kCCHmacAlgSHA512:
            return CC_SHA512_DIGEST_LENGTH;
        case kCCHmacAlgSHA1:
        default:
            return CC_SHA1_DIGEST_LENGTH;
    }
}

static NSString* getHOTP(CCHmacAlgorithm algo, uint8_t digits, NSData* key, uint64_t counter) {
#ifdef __LITTLE_ENDIAN__
    // Network byte order
    counter = (((uint64_t) htonl(counter)) << 32) + htonl(counter >> 32);
#endif
    
    // Create digits divisor
    uint32_t div = 1;
    for (int i = digits; i > 0; i--)
        div *= 10;
    
    // Create the HMAC
    uint8_t digest[getDigestLength(algo)];
    CCHmac(algo, [key bytes], [key length], &counter, sizeof(counter), digest);
    // Truncate
    uint32_t binary;
    uint32_t off = digest[sizeof(digest) - 1] & 0xf;
    binary  = (digest[off + 0] & 0x7f) << 0x18;
    binary |= (digest[off + 1] & 0xff) << 0x10;
    binary |= (digest[off + 2] & 0xff) << 0x08;
    binary |= (digest[off + 3] & 0xff) << 0x00;
    binary  = binary % div;
    return [NSString stringWithFormat:[NSString stringWithFormat:@"%%0%hhulu", digits], binary];
}

@implementation Token
{
    NSString* issuerInt;
	CCHmacAlgorithm algo;
    NSData*   key;
    uint64_t counter;
    uint32_t period;
}

- (id)initWithURL:(NSURL*)url {
    if (!(self = [super init]))
        return nil;
    
    NSString* scheme = [url scheme];
    if (scheme == nil || ![scheme isEqualToString:@"otpauth"])
        return nil;
    
    _type = [url host];
    if (_type == nil ||
        (![_type isEqualToString:@"totp"] &&
         ![_type isEqualToString:@"hotp"]))
        return nil;
    
    // Get the path and strip it of its leading '/'
    NSString* path = [url path];
    if (path == nil)
        return nil;
    while ([path hasPrefix:@"/"])
        path = [path substringFromIndex:1];
    if ([path length] == 0)
        return nil;
    
    // Get issuer and label
    NSArray* array = [path componentsSeparatedByString:@":"];
    if (array == nil || [array count] == 0)
        return nil;
    if ([array count] > 1) {
        _issuer = decode([array objectAtIndex:0]);
        _label = decode([array objectAtIndex:1]);
    } else {
        _issuer = @"";
        _label = decode([array objectAtIndex:0]);
    }
    // Parse query
    NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
    array = [[url query] componentsSeparatedByString:@"&"];
    for (NSString *kv in array) {
        NSArray *tmp = [kv componentsSeparatedByString:@"="];
        if (tmp.count != 2)
            continue;
        [query setValue:decode([tmp objectAtIndex:1]) forKey:[tmp objectAtIndex:0]];
    }
    
    // Get key
    key = parseKey([query objectForKey:@"secret"]);
    if (key == nil)
        return nil;
    
    // Get internal issuer
    issuerInt = [query objectForKey:@"issuer"];
    if (issuerInt == nil)
        issuerInt = _issuer;
    // Get algorithm and digits
    algo = parseAlgo([query objectForKey:@"algorithm"]);
    _digits = parseDigits([query objectForKey:@"digits"]);
    // Get counter or period
    if ([_type isEqualToString:@"hotp"]) {
        NSString *c = [query objectForKey:@"counter"];
        counter = c != nil ? [c longLongValue] : 0;
    } else if ([_type isEqualToString:@"totp"]) {
        NSString *p = [query objectForKey:@"period"];
        period = p != nil ? (int) [p integerValue] : 30;
        if (period == 0)
            period = 30;
    }
    
    return self;
}

- (id)initWithString:(NSString*)string {
    return [self initWithURL:[[NSURL alloc] initWithString:string]];
}

- (NSString*)description {
    NSString *tmp = [NSString
            stringWithFormat:@"otpauth://%@/%@:%@?algorithm=%s&digits=%lu&secret=%@&issuer=%@",
            _type, encode(_issuer), encode(_label), unparseAlgo(algo), _digits, unparseKey(key), encode(issuerInt)];
    if (tmp == nil)
        return nil;
    
    if ([_type isEqualToString:@"hotp"])
        return [NSString stringWithFormat:@"%@&counter=%llu", tmp, counter];
    if ([_type isEqualToString:@"totp"])
        return [NSString stringWithFormat:@"%@&period=%u", tmp, period];
    
    return nil;
}

- (void)increment {
    if ([_type isEqualToString:@"hotp"])
        counter++;
}

- (NSString*)value {
    return getHOTP(algo, _digits, key,
                   [_type isEqualToString:@"hotp"]
                     ? counter
                     : time(NULL) / period);
}

- (float)progress {
    struct timeval tv;
    
    if (gettimeofday(&tv, NULL) != 0)
        return 0;
    uint64_t time = tv.tv_sec * 1000 + tv.tv_usec / 1000;
    uint64_t p = period * 1000;
    
    return ((float) (time % p)) / p;
}

- (NSString*)uid {
    return [NSString stringWithFormat:@"%@:%@", issuerInt, _label];
}
@end
