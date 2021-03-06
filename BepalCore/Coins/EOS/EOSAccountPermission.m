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

#import "EOSAccountPermission.h"

@implementation EOSAccountPermission

- (instancetype)initWithString:(NSString*)account Permission:(NSString*)permission
{
    self = [super init];
    if (self) {
        _account = [[EOSAccountName alloc] initWithName:account];
        _permission = [[EOSAccountName alloc] initWithName:permission];
    }
    return self;
}

- (instancetype)initWithData:(NSData*)account Permission:(NSString*)permission
{
    self = [super init];
    if (self) {
        _account = [[EOSAccountName alloc] initWithHex:account];
        _permission = [[EOSAccountName alloc] initWithName:permission];
    }
    return self;
}

- (NSData*)toByte {
    NSMutableData *stream = [NSMutableData new];
    [stream appendData:_account.accountData];
    [stream appendData:_permission.accountData];
    return stream;
}

- (void)parse:(NSData*)data :(NSUInteger*)index {
    _account = [[EOSAccountName alloc] initWithHex:[data subdataWithRange:NSMakeRange(*index, 8)]];
    *index = *index + 8;
    _permission = [[EOSAccountName alloc] initWithHex:[data subdataWithRange:NSMakeRange(*index, 8)]];
    *index = *index + 8;
}

- (NSDictionary*)toJson {
    NSMutableDictionary *jsaccper = [NSMutableDictionary new];
    jsaccper[@"account"] = _account.accountName;
    jsaccper[@"permission"] = _permission.accountName;
    return jsaccper;
}

@end
