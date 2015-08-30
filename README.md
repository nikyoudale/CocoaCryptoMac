#CocoaCryptoMac

This is a simple project demonstrating how to migrate from certain OpenSSL APIs to Apple's native crypto libraries. I found documentation on this topic to sparse and generally not very helpful. Hopefully this will be useful to someone.

##Problem
I had some serial key generation and verification code which depends on OpenSSL for asymmetric encryption and decryption. The idea is pretty simple: serial key generation is done by encrypting some data with an RSA private key, and verification consists of decrypting that data with the matching RSA public key. This process is also known as signing and verifying, and there are a bunch of standardised algorithms for doing that, however in this case it's custom - an arbitrary piece of data is encrypted.

Let's get concrete:

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

i.e. the header and footer are missing the words "RSA". These are just different encodings of the same public key. There's an excellent answer on stackoverflow talking about this: http://stackoverflow.com/a/29707204/692395

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

Encrypting with public key on the command line:
% echo "hello world" | openssl rsautl -inkey public_key.pem -pubin -pkcs -encrypt | base64
IXy6nfUM2Pjq75ZJ+yxxCEhiJ6UH75xX5dGdPhwkJJBNarN5euEqSNEFDPJ6+AmRuX2smUYCL7TLwqu20RK3QQ==

Decrypting with private key on the command line:
echo "IXy6nfUM2Pjq75ZJ+yxxCEhiJ6UH75xX5dGdPhwkJJBNarN5euEqSNEFDPJ6+AmRuX2smUYCL7TLwqu20RK3QQ==" | base64 -D | openssl rsautl -inkey private_key.pem -pkcs -decrypt


That's great, but how do we decrypt that in Mac app *without* OpenSSL?

##Doing it in with Apple's APIs
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

Essentially, what this means is that if your public key has the `-----BEGIN PUBLIC KEY-----` use `kSecFormatOpenSSL`, otherwise if the header is `-----BEGIN RSA PUBLIC KEY-----` then use `kSecFormatBSAFE`. I have no idea what BSAFE refers to.

This logic is all encapsulated in `CCMKeyLoader`, you just need to know what format your key is in. Then call `loadRSAPEMPublicKey:` or `loadX509PEMPublicKey:`.


