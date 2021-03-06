#CocoaCryptoMac

This is a simple project demonstrating how to migrate from certain OpenSSL APIs to Apple's native crypto libraries. I found documentation on this topic to sparse and generally not very helpful. Hopefully this will be useful to someone.

##Problem
I had some existing code using the OpenSSL library, which was available on Mac OS X until 10.7 when it marked as deprecated. Since then, until 10.11, the OpenSSL library has still existed on the system, so you could still compile with warnings. From 10.11 onwards, the OpenSSL headers have been removed making compilation not possible, however the dynamic library still seems to be included with OS, so existing apps linked to it will still work, for a while.

The code is something like this:
```
char *publicKeyPEM = "-----BEGIN RSA PUBLIC KEY-----\n\
MEgCQQCWz+w+xADL55+XhJHzptMgHnSJkh6hfAtPuNSN8Fpw9qJuvPx42hN7H2R5\n\
adZ37GqSdmNl9feeCydT8TqFLwm9AgMBAAE=\n\
-----END RSA PUBLIC KEY-----";

BIO *pubBio = BIO_new_mem_buf((void *)publicKeyPEM, (int)strlen(publicKeyPEM)+1);
RSA pubRSA = RSA_new();
PEM_read_bio_RSAPublicKey(pubBio, &pubRSA, NULL, NULL);
int len;
uint8_t *buf = malloc(RSA_size(pubRSA));
unsigned char *encrypted = ...;
RSA_public_decrypt(len, encrypted, buf, pub, RSA_PKCS1_PADDING);
```

Nevermind why it does something so non-standard ('encrypting' with the private key doesn't really 'encrypt' it because anyone with the public key can 'decrypt'). This is basically how signatures work with RSA keys.


##The keys
I had a private key that looks like this:

private_key.pem:
```
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAJbP7D7EAMvnn5eEkfOm0yAedImSHqF8C0+41I3wWnD2om68/Hja
E3sfZHlp1nfsapJ2Y2X1954LJ1PxOoUvCb0CAwEAAQJABMuv038gF1vSM1s/2OOh
KxBM3GMNHk13fp1+BNVzysvAd21Hl1O9A3ia3O4Aw25CPIAzTyFOjZa3iXCmfNFO
gQIhAMVxpzuu/dx0zlFlnVLgKDy+LizKSQisk9j32cVX4dqVAiEAw4nkPv6EteS0
iNDd/r+v1A/t029gkLy79WdettbY0IkCIQDC89OSRNj4goTtLg5HNHnGcGobY6j1
XaGmTCPEjV++eQIgAW0aCxOUKDd40Z6kX91KDQPouigPzj5yKIIOgMrkXfECICMP
RsPAqDkBRTg3oiATeKM1937vLMsYVIEYETr6wmt2
-----END RSA PRIVATE KEY-----
```

And a public key like this:

public_key.pem
```
-----BEGIN RSA PUBLIC KEY-----
MEgCQQCWz+w+xADL55+XhJHzptMgHnSJkh6hfAtPuNSN8Fpw9qJuvPx42hN7H2R5
adZ37GqSdmNl9feeCydT8TqFLwm9AgMBAAE=
-----END RSA PUBLIC KEY-----
```

You've probably also seen public keys in the following format:

```
-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAJbP7D7EAMvnn5eEkfOm0yAedImSHqF8
C0+41I3wWnD2om68/HjaE3sfZHlp1nfsapJ2Y2X1954LJ1PxOoUvCb0CAwEAAQ==
-----END PUBLIC KEY-----
```

i.e. the header and footer are missing the words "RSA". These are just different encodings of the same public key. There's an excellent answer on stackoverflow talking about this: http://stackoverflow.com/a/29707204/692395. More good info here: http://blog.oddbit.com/2011/05/08/converting-openssh-public-keys/.

The first format is also known as PEM DER ASN.1 PKCS#1 RSA Public key

The second format is also known as X.509 SubjectPublicKeyInfo/OpenSSL PEM public key.

It's easy to convert from one format to the other.

RSA -> X.509:
```
% openssl rsa -RSAPublicKey_in -in public_key.rsa.pem
writing RSA key
-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAJbP7D7EAMvnn5eEkfOm0yAedImSHqF8
C0+41I3wWnD2om68/HjaE3sfZHlp1nfsapJ2Y2X1954LJ1PxOoUvCb0CAwEAAQ==
-----END PUBLIC KEY-----
```

X.509 -> RSA:
```
% openssl rsa -pubin -in public_key.x509.pem -RSAPublicKey_out
writing RSA key
-----BEGIN RSA PUBLIC KEY-----
MEgCQQCWz+w+xADL55+XhJHzptMgHnSJkh6hfAtPuNSN8Fpw9qJuvPx42hN7H2R5
adZ37GqSdmNl9feeCydT8TqFLwm9AgMBAAE=
-----END RSA PUBLIC KEY-----
```

To generate a new RSA keypair with OpenSSL:

```
openssl genrsa -out private_key.pem 512
openssl rsa -pubout -in private_key.pem -out public_key.pem
```

private_key.pem:
```
-----BEGIN RSA PRIVATE KEY-----
MIIBOgIBAAJBAJbP7D7EAMvnn5eEkfOm0yAedImSHqF8C0+41I3wWnD2om68/Hja
E3sfZHlp1nfsapJ2Y2X1954LJ1PxOoUvCb0CAwEAAQJABMuv038gF1vSM1s/2OOh
KxBM3GMNHk13fp1+BNVzysvAd21Hl1O9A3ia3O4Aw25CPIAzTyFOjZa3iXCmfNFO
gQIhAMVxpzuu/dx0zlFlnVLgKDy+LizKSQisk9j32cVX4dqVAiEAw4nkPv6EteS0
iNDd/r+v1A/t029gkLy79WdettbY0IkCIQDC89OSRNj4goTtLg5HNHnGcGobY6j1
XaGmTCPEjV++eQIgAW0aCxOUKDd40Z6kX91KDQPouigPzj5yKIIOgMrkXfECICMP
RsPAqDkBRTg3oiATeKM1937vLMsYVIEYETr6wmt2
-----END RSA PRIVATE KEY-----
```

public_key.pem:
```
-----BEGIN PUBLIC KEY-----
MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAJbP7D7EAMvnn5eEkfOm0yAedImSHqF8
C0+41I3wWnD2om68/HjaE3sfZHlp1nfsapJ2Y2X1954LJ1PxOoUvCb0CAwEAAQ==
-----END PUBLIC KEY-----
```

##OpenSSL command line
###EncPub, DecPriv (a.k.a. encrypt, decrypt)
Encrypting with public key on the command line:
```
% echo "hello world" \
  | openssl rsautl -inkey public_key.pem -pubin -pkcs -encrypt \
  | base64
IXy6nfUM2Pjq75ZJ+yxxCEhiJ6UH75xX5dGdPhwkJJBNarN5euEqSNEFDPJ6+AmRuX2smUYCL7TLwqu20RK3QQ==
```

Decrypting with private key on the command line:
```
echo "IXy6nfUM2Pjq75ZJ+yxxCEhiJ6UH75xX5dGdPhwkJJBNarN5euEqSNEFDPJ6+AmRuX2smUYCL7TLwqu20RK3QQ==" \
  | base64 -D \
  | openssl rsautl -inkey private_key.pem -pkcs -decrypt
```

###EncPriv, DecPub (a.k.a. sign, verify)
Encrypting with private key on the command line:
```
% echo "hello world" \
  | openssl rsautl -sign -inkey private_key.pem \
  | base64
G1ihO3NRBiA4nygDsDSYLWEpKo5I08/fnCo4Xoj5lrJl5A/WhFrGsmYyNlXLqve8k5CsBjToPb2q03sVZSii9g==
```

Decrypting with public key on the command line:
```
% echo "G1ihO3NRBiA4nygDsDSYLWEpKo5I08/fnCo4Xoj5lrJl5A/WhFrGsmYyNlXLqve8k5CsBjToPb2q03sVZSii9g==" \
  | base64 -D \
  | openssl rsautl -verify -inkey public_key.pem -pubin
```

It is this latter pair of operations that we want to replicate in a Mac app *without* OpenSSL.

##Doing it with Apple's APIs
###Step 1: Load the key
This is harder than it sounds. In summary, you need to use SecItemImport and pass NULL for the keychain parameter (this means don't store it a keychain, just load it in memory). The next complication is the value for the `SecExternalFormat` parameter. The correct value to use can only be determined by looking at the source code for `SecImportExportUtils.cpp`, which includes this handy table:

```
/*
 * For the record, here is the mapping of SecExternalFormat, algorithm, and key 
 * class to CSSM-style key format (CSSM_KEYBLOB_FORMAT - 
 * CSSM_KEYBLOB_RAW_FORMAT_X509, etc). The entries in the table are the 
 * last component of a CSSM_KEYBLOB_FORMAT. Format kSecFormatUnknown means
 * "default for specified class and algorithm", which is currently the 
 * same as kSecFormatOpenSSL.
 *
 *                                          algorithm/class
 *                              RSA                DSA                   DH
 *                        ----------------  ----------------  ----------------
 * SecExternalFormat     priv      pub     priv      pub     priv      pub
 * -----------------    -------  -------  -------  -------  -------  -------
 * kSecFormatOpenSSL     PKCS1    X509    OPENSSL   X509     PKCS3    X509
 * kSecFormatBSAFE       PKCS8    PKCS1   FIPS186   FIPS186  PKCS8    not supported
 * kSecFormatUnknown     PKCS1    X509    OPENSSL   X509     PKCS3    X509
 * kSecFormatSSH          SSH      SSH      n/s     n/s       n/s     n/s
 * kSecFormatSSHv2        n/s     SSH2      n/s     SSH2      n/s     n/s
 */
```
Source: http://www.opensource.apple.com/source/libsecurity_keychain/libsecurity_keychain-24850/lib/SecImportExportUtils.cpp?txt

Essentially, what this means is that if your public key has the `-----BEGIN PUBLIC KEY-----` use `kSecFormatOpenSSL`, otherwise if the header is `-----BEGIN RSA PUBLIC KEY-----` then use `kSecFormatBSAFE`. I have no idea what BSAFE refers to.

This logic is all encapsulated in `CCMKeyLoader`, you just need to know what format your key is in. Then call `loadRSAPEMPublicKey:` or `loadX509PEMPublicKey:`.

###Step 2: Decrypt
It would be nice to be able to use `SecDecryptTransform`, however that doesn't seem to accept public keys for decryption. Apple's docs say that when you can't do something with the higher level Security framework functions, then fallback to the deprecated CSSM functions. The implementation is insanely complicated and generally vile, but it works. See `CSSMRSACryptor`.

```
NSData *decryptedData = [cryptor decryptData:inputData
                                 withPublicKey:key
                                         error:&error];
NSString *output = [[NSString alloc] initWithData:decryptedData encoding:NSUTF8StringEncoding];
```

So there you go. Pretty messy, but possible.

##Credits
This code was very helpful and forms the basis of `CSSMRSACryptor`: https://github.com/karstenBriksoft/CSSMPublicKeyDecrypt
