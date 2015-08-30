//
//  CCMCryptor.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import "CCMCryptor.h"
#import "CCMPublicKey.h"
#import "CSSMPublicKeyDecryptor.h"

@implementation CCMCryptor {
  CSSMPublicKeyDecryptor *_cssmDecryptor;
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _cssmDecryptor = [[CSSMPublicKeyDecryptor alloc] init];
  }
  return self;
}

- (NSData *)decryptData:(NSData *)encryptedData withPublicKey:(CCMPublicKey *)key error:(NSError **)errorPtr {
  return [_cssmDecryptor decryptData:encryptedData
                       withPublicKey:key
                               error:errorPtr];
}

@end
