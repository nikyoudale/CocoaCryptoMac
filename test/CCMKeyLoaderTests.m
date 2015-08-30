//
//  CCMKeyLoaderTests.m
//  CocoaCryptoMac
//
//  Created by Nik Youdale on 30/08/2015.
//  Copyright (c) 2015 Nik Youdale. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import "CCMKeyLoader.h"

@interface CCMKeyLoaderTests : XCTestCase

@end

@implementation CCMKeyLoaderTests {
  NSString *publicRSAPEM;
  NSString *publicX509PEM;
  NSString *privateRSAPEM;
}

- (void)setUp {
  [super setUp];
  publicRSAPEM = [self loadPEMKeyResource:@"public_key.rsa"];
  publicX509PEM = [self loadPEMKeyResource:@"public_key.x509"];
  privateRSAPEM = [self loadPEMKeyResource:@"private_key"];
}

- (void)testLoadRSAPublicKey {
  CCMKeyLoader *loader = [[CCMKeyLoader alloc] init];
  CCMPublicKey *key = [loader loadRSAPEMPublicKey:publicRSAPEM];
  XCTAssertNotNil(key);
}

- (void)testLoadX509PublicKey {
  CCMKeyLoader *loader = [[CCMKeyLoader alloc] init];
  CCMPublicKey *key = [loader loadX509PEMPublicKey:publicX509PEM];
  XCTAssertNotNil(key);
}

- (void)testFailToLoadRSAPublicKeyAsX509 {
  CCMKeyLoader *loader = [[CCMKeyLoader alloc] init];
  CCMPublicKey *key = [loader loadX509PEMPublicKey:publicRSAPEM];
  XCTAssertNil(key);
}

- (void)testFailToLoadX509PublicKeyAsRSA {
  CCMKeyLoader *loader = [[CCMKeyLoader alloc] init];
  CCMPublicKey *key = [loader loadRSAPEMPublicKey:publicX509PEM];
  XCTAssertNil(key);
}

- (void)testLoadRSAPrivateKey {
  CCMKeyLoader *loader = [[CCMKeyLoader alloc] init];
  CCMPrivateKey *key = [loader loadRSAPEMPrivateKey:privateRSAPEM];
  XCTAssertNotNil(key);
}

- (NSString *)loadPEMKeyResource:(NSString *)name {
  NSBundle *bundle = [NSBundle bundleForClass:[CCMKeyLoaderTests class]];
  NSURL *url = [bundle URLForResource:name withExtension:@"pem"];
  NSAssert(url != nil, @"file not found");
  return [NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
}

@end
