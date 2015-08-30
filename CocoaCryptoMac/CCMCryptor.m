//
//  CCMCryptor.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CCMCryptor.h"
#import "CCMPublicKey.h"
#import "CSSMRSACryptor.h"
#import "CCMPrivateKey.h"

@implementation CCMCryptor {
  CSSMRSACryptor *_cssmCryptor;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _cssmCryptor = [[CSSMRSACryptor alloc] init];
  }
  return self;
}

- (NSData *)decryptData:(NSData *)encryptedData withPublicKey:(CCMPublicKey *)key error:(NSError **)errorPtr {
  return [_cssmCryptor decryptData:encryptedData
                     withPublicKey:key
                             error:errorPtr];
}

- (NSData *)encryptData:(NSData *)data withPrivateKey:(CCMPrivateKey *)key error:(NSError **)errorPtr {
  return [_cssmCryptor encryptData:data
                    withPrivateKey:key
                             error:errorPtr];
}

@end
