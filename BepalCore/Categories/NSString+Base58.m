/*
 * Copyright (c) 2018-2019, BEPAL
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the University of California, Berkeley nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "NSString+Base58.h"
#import "base58.h"
#import "Security.h"
#import "NSMutableData+Extend.h"
#import "NSData+Hash.h"

@implementation NSString (Base58)

static const UniChar base58chars[] = {
    '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'm', 'n',
    'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'
};

+ (NSString *)base58WithData:(NSData *)d {
    if (! d) return nil;
    
    size_t i, z = 0;
    
    while (z < d.length && ((const uint8_t *)d.bytes)[z] == 0) z++; // count leading zeroes
    
    uint8_t buf[(d.length - z)*138/100 + 1]; // log(256)/log(58), rounded up
    
    memset(buf, 0, sizeof(buf));
    
    for (i = z; i < d.length; i++) {
        uint32_t carry = ((const uint8_t *)d.bytes)[i];
        
        for (size_t j = sizeof(buf); j > 0; j--) {
            carry += (uint32_t)buf[j - 1] << 8;
            buf[j - 1] = carry % 58;
            carry /= 58;
        }
        
        memset(&carry, 0, sizeof(carry));
    }
    
    i = 0;
    while (i < sizeof(buf) && buf[i] == 0) i++; // skip leading zeroes
    
    CFMutableStringRef s = CFStringCreateMutable(SecureAllocator(), z + sizeof(buf) - i);
    
    while (z-- > 0) CFStringAppendCharacters(s, &base58chars[0], 1);
    while (i < sizeof(buf)) CFStringAppendCharacters(s, &base58chars[buf[i++]], 1);
    memset(buf, 0, sizeof(buf));
    return CFBridgingRelease(s);
}

+ (NSString *)base58checkWithData:(NSData *)d {
    NSMutableData *data = [NSMutableData new];
    [data appendData:d];
    [data appendData:[[d SHA256_2] subdataWithRange:NSMakeRange(0, 4)]];
    return [NSString base58WithData:data];
}

- (NSData *)base58ToData {
    size_t i, z = 0;
    
    while (z < self.length && [self characterAtIndex:z] == base58chars[0]) z++; // count leading zeroes
    
    uint8_t buf[(self.length - z)*733/1000 + 1]; // log(58)/log(256), rounded up
    
    memset(buf, 0, sizeof(buf));
    
    for (i = z; i < self.length; i++) {
        uint32_t carry = [self characterAtIndex:i];
        
        switch (carry) {
            case '1': case '2': case '3': case '4': case '5': case '6': case '7': case '8': case '9':
                carry -= '1';
                break;
                
            case 'A': case 'B': case 'C': case 'D': case 'E': case 'F': case 'G': case 'H':
                carry += 9 - 'A';
                break;
                
            case 'J': case 'K': case 'L': case 'M': case 'N':
                carry += 17 - 'J';
                break;
                
            case 'P': case 'Q': case 'R': case 'S': case 'T': case 'U': case 'V': case 'W': case 'X': case 'Y':
            case 'Z':
                carry += 22 - 'P';
                break;
                
            case 'a': case 'b': case 'c': case 'd': case 'e': case 'f': case 'g': case 'h': case 'i': case 'j':
            case 'k':
                carry += 33 - 'a';
                break;
                
            case 'm': case 'n': case 'o': case 'p': case 'q': case 'r': case 's': case 't': case 'u': case 'v':
            case 'w': case 'x': case 'y': case 'z':
                carry += 44 - 'm';
                break;
                
            default:
                carry = UINT32_MAX;
        }
        
        if (carry >= 58) break; // invalid base58 digit
        
        for (size_t j = sizeof(buf); j > 0; j--) {
            carry += (uint32_t)buf[j - 1]*58;
            buf[j - 1] = carry & 0xff;
            carry >>= 8;
        }
        
        memset(&carry, 0, sizeof(carry));
    }
    
    i = 0;
    while (i < sizeof(buf) && buf[i] == 0) i++; // skip leading zeroes
    
    NSMutableData *d = [NSMutableData secureDataWithCapacity:z + sizeof(buf) - i];
    
    d.length = z;
    [d appendBytes:&buf[i] length:sizeof(buf) - i];
    memset(buf, 0, sizeof(buf));
    return d;
}

- (NSData *)base58checkToData {
    NSData *d = self.base58ToData;
    
    if (d.length < 4) return nil;
    
    NSData *data = CFBridgingRelease(CFDataCreate(SecureAllocator(), d.bytes, d.length - 4));
    
    // verify checksum
    NSData *datachecksum1 = [[data SHA256_2] subdataWithRange:NSMakeRange(0, 4)];
    NSData *datachecksum2 = [d subdataWithRange:NSMakeRange(d.length - 4, 4)];
    if (![datachecksum1 isEqual:datachecksum2]) return nil;
    return data;
}

+ (NSString *)hexWithData:(NSData *)d {
    return [Security toHexString:d];
}

- (NSData *)hexToData {
    return [Security fromHexString:self];
}

- (NSData *)addressToHash160 {
    NSData *d = self.base58checkToData;
    return (d.length == 160 / 8 + 1) ? [d subdataWithRange:NSMakeRange(1, d.length - 1)] : nil;
}

@end
