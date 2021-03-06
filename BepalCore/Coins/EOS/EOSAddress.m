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

#import "EOSAddress.h"
#import "NSData+Hash.h"
#import "NSString+Base58.h"

@implementation EOSAddress

- (instancetype)init:(NSData*)pubKey
{
    self = [super init];
    if (self) {
        pubkey = pubKey;
    }
    return self;
}

- (NSString*)toAddress {
    NSString *EOS_PREFIX = @"EOS";
    NSMutableData *pub = [NSMutableData new];
    [pub appendData:pubkey];
    [pub appendData:[pubkey.RMD160 subdataWithRange:NSMakeRange(0, 4)]];
    NSMutableString *address = [NSMutableString new];
    [address appendString:EOS_PREFIX];
    [address appendString:[NSString base58WithData:pub]];
    return address;
}

+ (NSData*)toPubKey:(NSString*)address {
    NSString *naddr = [address substringWithRange:NSMakeRange(3, address.length - 3)];
    NSData* daddr = naddr.base58ToData;
    return [daddr subdataWithRange:NSMakeRange(0, daddr.length - 4)];
}

@end
