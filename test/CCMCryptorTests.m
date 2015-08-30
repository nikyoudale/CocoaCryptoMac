//
//  CCMCryptorTests.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CCMBase64.h"
#import "CCMCryptor.h"
#import "CCMPublicKey.h"
#import "CCMKeyLoader.h"

@interface CCMCryptorTests : XCTestCase

@end

@implementation CCMCryptorTests {
  CCMCryptor *cryptor;
}

- (void)setUp {
  [super setUp];
  cryptor = [[CCMCryptor alloc] init];
}

- (void)testDecryptHelloWorld {
  // This was produced on the command line with the following command:
  // % echo -n "hello world" \
  //   | openssl rsautl -sign -inkey test/resources/private_key.pem \
  //   | base64
  NSString *input = @"UXxhr/PwcKFLowY67ptiWAwZW+cpwj64rMRbx08935xCAWOjqH9FKEBHtwISjFwf+tKctZUGevIPDAvKSru3Avj"
      "4BoBh+JUYZ+Uf5sbWNACTUKbc0+886HfxccYDNr/ahTV0tfYQ5Xmzxa8c8WoB11h8s6cvI5aLAS6AIe/E9pI=";
  NSData *inputData = [CCMBase64 dataFromBase64String:input];
  CCMPublicKey *key = [self loadPublicKeyResource:@"public_key.x509"];
  NSError *error;
  NSData *decryptedData = [cryptor decryptData:inputData
                                 withPublicKey:key
                                         error:&error];
  NSString *output = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
  XCTAssertEqualObjects(@"hello world", output);
}

- (void)testEncryptHelloWorld {
  NSData *inputData = [@"hello world" dataUsingEncoding:NSUTF8StringEncoding];
  CCMPrivateKey *key = [self loadPrivateKeyResource:@"private_key"];
  NSError *error;
  NSData *encryptedData = [cryptor encryptData:inputData withPrivateKey:key error:&error];
  NSString *output = [CCMBase64 base64StringFromData:encryptedData];
  // This can be decrypted on the command line with the following command:
  // % ( echo -n "UXxhr/PwcKFLowY67ptiWAwZW+cpwj64rMRbx08935xCAWOjqH9FKEBHtwISjFwf+tKctZUGevIPDAvKSru3Avj";
  //     echo -n "4BoBh+JUYZ+Uf5sbWNACTUKbc0+886HfxccYDNr/ahTV0tfYQ5Xmzxa8c8WoB11h8s6cvI5aLAS6AIe/E9pI=") \
  //   | base64 -D \
  //   | openssl rsautl -verify -inkey test/resources/public_key.x509.pem -pubin
  NSString *expected = @"UXxhr/PwcKFLowY67ptiWAwZW+cpwj64rMRbx08935xCAWOjqH9FKEBHtwISjFwf+tKctZUGevIPDAvKSru3Avj"
      "4BoBh+JUYZ+Uf5sbWNACTUKbc0+886HfxccYDNr/ahTV0tfYQ5Xmzxa8c8WoB11h8s6cvI5aLAS6AIe/E9pI=";
  XCTAssertEqualObjects(expected, output);
}

- (CCMPublicKey *)loadPublicKeyResource:(NSString *)name {
  NSString *pem = [self loadPEMResource:name];
  CCMKeyLoader *keyLoader = [[CCMKeyLoader alloc] init];
  return [keyLoader loadX509PEMPublicKey:pem];
}

- (CCMPrivateKey *)loadPrivateKeyResource:(NSString *)name {
  NSString *pem = [self loadPEMResource:name];
  CCMKeyLoader *keyLoader = [[CCMKeyLoader alloc] init];
  return [keyLoader loadRSAPEMPrivateKey:pem];
}

- (NSString *)loadPEMResource:(const NSString *)name {
  NSBundle *bundle = [NSBundle bundleForClass:[CCMCryptorTests class]];
  NSURL *url = [bundle URLForResource:name withExtension:@"pem"];
  NSAssert(url != nil, @"file not found");
  NSString *pem = [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
  return pem;
}

@end
