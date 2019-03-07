//
//  EosECKey.m
//  ectest
//
//  Created by 潘孝钦 on 2018/3/20.
//  Copyright © 2018年 潘孝钦. All rights reserved.
//

#import "EosECKey.h"
#import "BitECKey.h"
#import "SDKStaticPara.h"
#import "Categories.h"
#import "ErrorTool.h"
#import "secp256k1.h"
#import "EOSAddress.h"

@interface EosECKey() {
    const ecdsa_curve *curve;
}

@end

@implementation EosECKey

- (instancetype)init
{
    self = [super init];
    if (self) {
        curve = &secp256k1;
//        ctx = secp256k1_context_create(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY | SECP256K1_CONTEXT_COMMIT | SECP256K1_CONTEXT_RANGEPROOF);
    }
    return self;
}

- (instancetype)initWithKey:(NSData*)priKey Pub:(NSData*)pubKey {
    self = [self init];
    if (self) {
        privateKey = priKey;
        if (pubKey == nil && privateKey != nil) {
            publicKey = [BitECKey prvKeyToPubKey:priKey];
        } else {
            publicKey = pubKey;
        }
        
        NSArray *len = [self getKeyLength];
        [ErrorTool checkArgument:
         privateKey == nil || privateKey.length == [len[0] intValue]
                            Mess:@"privateKey error"
                             Log:[NSString stringWithFormat:@"%@  %lu  %@",privateKey.hexString,(unsigned long)privateKey.length,len[0]]];
        [ErrorTool checkArgument:
         publicKey == nil || publicKey.length == [len[1] intValue]
                            Mess:@"publicKey error"
                             Log:[NSString stringWithFormat:@"%@  %lu  %@",publicKey.hexString,(unsigned long)publicKey.length,len[1]]];
    }
    return self;
}

//- (ECSign*)sign:(NSData*)mess {
//    uint8_t sig[64];
//    const uint8_t *msg = (const uint8_t *)mess.bytes;
//    uint8_t hash[32];
//    hasher_Raw(HASHER_SHA2, msg, mess.length, hash);
//    uint8_t pub[33];
//    memcpy(pub, publicKey.bytes, 33);
//    int recid = 1;
//    secp256k1_ecdsa_sign_compact(ctx, hash, sig, privateKey.bytes, NULL, NULL, &recid);
//    memzero(hash, sizeof(hash));
//    memzero(pub, sizeof(pub));
//    return [[ECSign alloc] initWithBytes:sig V:recid];
//}

int isCanonicalEOS(uint8_t by, uint8_t sig[64]) {
    return !(sig[0] & 0x80)
    && !(sig[0] == 0 && !(sig[1] & 0x80))
    && !(sig[32] & 0x80)
    && !(sig[32] == 0 && !(sig[33] & 0x80));
}

//- (BOOL)is_canonical:(uint8_t *)data {
//    return !(data[1] & 0x80)
//    && !(data[1] == 0 && !(data[2] & 0x80))
//    && !(data[33] & 0x80)
//    && !(data[33] == 0 && !(data[34] & 0x80));
//}

- (ECSign*)sign:(NSData*)mess {
    uint8_t sig[64];
    uint8_t hash[32];
    memcpy(hash, mess.bytes, 32);
    uint8_t recid = 1;
    @synchronized([[SDKStaticPara getOrCreate] getSynchronizedDeterministicKey]) {
        ecdsa_sign_digest_nonce(curve, privateKey.bytes, hash, sig, &recid, isCanonicalEOS);
    }
    
    memzero(hash, sizeof(hash));
    return [[ECSign alloc] initWithBytes:sig V:recid];
}

//- (Boolean)verify:(NSData*)mess :(ECSign*)sig {
//    uint8_t hash[32];
//    memcpy(hash, mess.bytes, 32);
//    unsigned char pub[33];
//    int pubkeylen;
//    int recid = sig.V;
//    int result = 0;
//    if (![self is_canonical:(uint8_t*)[[sig encoding:true] bytes]]) {
//        return false;
//    }
//    @synchronized([[SDKStaticPara getOrCreate] getSynchronizedDeterministicKey]) {
//        result = secp256k1_ecdsa_recover_compact(ctx, hash, sig.toDataNoV.bytes, pub, &pubkeylen, 1, recid);
//    }
//    memzero(hash, sizeof(hash));
//    return result == 1 && strncmp(publicKey.bytes, (char*)pub, pubkeylen) == 0;
//}

- (Boolean)verify:(NSData*)mess :(ECSign*)sig {
    uint8_t hash[32];
    memcpy(hash, mess.bytes, 32);
    uint8_t pub[33];
    memcpy(pub, publicKey.bytes, 33);
    int result = 0;
    @synchronized([[SDKStaticPara getOrCreate] getSynchronizedDeterministicKey]) {
        result = ecdsa_verify_digest(curve, pub, sig.toDataNoV.bytes, hash);
    }
    memzero(hash, sizeof(hash));
    memzero(pub, sizeof(pub));
    return result == 0;
}

- (NSArray*)getKeyLength {
    return @[@32,@33];
}

- (NSString*)toPubblicKeyString {
    return [[EOSAddress alloc] init:publicKey].toAddress;
}

- (NSString*)toWif {
    NSMutableData *resultWIFBytes = [NSMutableData new];
    [resultWIFBytes appendUInt8:0x80];
    [resultWIFBytes appendData:privateKey];
    [resultWIFBytes appendData:[resultWIFBytes.SHA256_2 subdataWithRange:NSMakeRange(0, 4)]];
    return [NSString base58WithData:resultWIFBytes];
}

@end
