//
//  KeyPair.m
//
//  Created by David Westbrook on 10/14/14.
//  Copyright (c) 2014 University of Massachusetts. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#include <CommonCrypto/CommonDigest.h>
#import "KeyPair.h"

const size_t KEY_SIZE = 1024;

const size_t BUFFER_SIZE = 64;
const size_t CIPHER_BUFFER_SIZE = 1024;
const uint32_t PADDING = kSecPaddingNone;

@implementation KeyPair

- (id)init {
    self = [super init];
    
    if(self) {
        debuggingEnabled = false;
        [self generateKeyPair];
        // Could just make guid an instance variable and
        // also set all of this in the generateKeyPair call.
        NSString *guid = [self sha1PublicKeyToString];
        publicString = [guid stringByAppendingString:@"-public"];
        privateString = [guid stringByAppendingString:@"-private"];
        publicTag = [publicString dataUsingEncoding:NSUTF8StringEncoding];
        privateTag = [privateString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return self;
}

- (id)initWithGuid:(NSString *)guid {
    self = [super init];
    
    if(self) {
        debuggingEnabled = false;
        // These are set to null because we get the references later - it's lazy.
        publicKey = NULL;
        privateKey = NULL;
        publicString = [guid stringByAppendingString:@"-public"];
        privateString = [guid stringByAppendingString:@"-private"];
        publicTag = [publicString dataUsingEncoding:NSUTF8StringEncoding];
        privateTag = [privateString dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    return self;
}

-(SecKeyRef)getPublicKeyRef {
    
    // did we already create it?
    if (publicKey != NULL) {
        return publicKey;
    }
    
    // can we look it up in the keychain?
    publicKey = [self getPublicKeyRefFromKeyChain];
    
    // if not then we create it
    if (publicKey == NULL) {
        // lazy generation of keypair
        if (debuggingEnabled) NSLog(@"************ %@ GenerateKeyPair in getPublicKeyRef", publicString);
        [self generateKeyPair];
    }
    
    // and get the reference from the key chain
    publicKey = [self getPublicKeyRefFromKeyChain];
    
    return publicKey;
}

-(SecKeyRef)getPublicKeyRefFromKeyChain {
    if (debuggingEnabled) NSLog(@"************ %@ getPublicKeyRefFromKeyChain", publicString);
    OSStatus resultCode = noErr;
    SecKeyRef publicKeyReference = NULL;
        
    NSMutableDictionary *queryPublicKey = [[NSMutableDictionary alloc] init];
    
    // Set the public key query dictionary.
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:publicTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    // Get the key.
    resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyReference);
    if (debuggingEnabled) NSLog(@"getPublicKeyRef: result code: %ld", (long)resultCode);
    
    if (resultCode != noErr)
    {
        publicKeyReference = NULL;
    }
    return publicKeyReference;
}

// slightly stupid way of doing this using SecItemAdd with a dummy value for kSecAttrApplicationTag which we then delete
// because the version using SecItemCopyMatching didn't work.
- (NSData *)getPublicKeyBits {
    if (debuggingEnabled) NSLog(@"************ %@ getPublicKeyBits", publicString);
    // insure that publicKey is bound
    [self getPublicKeyRef];
    
    static const uint8_t publicKeyIdentifier[] = "edu.umass.cs.gns.dummy.publickey";
    NSData *dummyPublicTag = [[NSData alloc] initWithBytes:publicKeyIdentifier length:sizeof(publicKeyIdentifier)];
    
    OSStatus sanityCheck = noErr;
    NSData * publicKeyBits = nil;
    
    NSMutableDictionary * queryPublicKey = [[NSMutableDictionary alloc] init];
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:dummyPublicTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    // Temporarily add key to the Keychain, return as data:
    NSMutableDictionary * attributes = [queryPublicKey mutableCopy];
    [attributes setObject:(__bridge id)publicKey forKey:(__bridge id)kSecValueRef];
    [attributes setObject:@YES forKey:(__bridge id)kSecReturnData];
    CFTypeRef result;
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) attributes, &result);
    if (sanityCheck == errSecSuccess) {
        publicKeyBits = CFBridgingRelease(result);
        
        // Remove from Keychain again:
        (void)SecItemDelete((__bridge CFDictionaryRef) queryPublicKey);
    }
    
    return publicKeyBits;
}

- (SecKeyRef)getPrivateKeyRef {
    
    // did we already create it?
    if (privateKey != NULL) {
        return privateKey;
    }
    
    // can we look it up in the keychain?
    privateKey = [self getPrivateKeyRefFromKeyChain];
    
    // if not then we create it
    if (privateKey == NULL) {
        // lazy generation of keypair
        if (debuggingEnabled) NSLog(@"************ %@ GenerateKeyPair in getPrivateKeyRef", privateString);
        [self generateKeyPair];
    }
    
    // and get the reference from the key chain
    privateKey = [self getPrivateKeyRefFromKeyChain];
    
    return privateKey;
}

- (SecKeyRef)getPrivateKeyRefFromKeyChain {
    if (debuggingEnabled) NSLog(@"************ %@ getPrivateKeyRefFromKeyChain", privateString);
    OSStatus resultCode = noErr;
    SecKeyRef privateKeyReference = NULL;
    NSMutableDictionary * queryPrivateKey = [[NSMutableDictionary alloc] init];
    
    // Set the private key query dictionary.
    [queryPrivateKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPrivateKey setObject:privateTag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPrivateKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPrivateKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    // Get the key.
    resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)queryPrivateKey, (CFTypeRef *)&privateKeyReference);
    if (debuggingEnabled) NSLog(@"getPrivateKeyRef: result code: %ld", (long)resultCode);
    
    if(resultCode != noErr)
    {
        privateKeyReference = NULL;
    }
    
    return privateKeyReference;
}

// this forces creation of a new keypair... don't call this unless
// you wnat to blow away an existing pair.
// Use the lazy methods getPublicKeyRef and getPrivateKeyRef instead.
- (void)generateKeyPair {
    
    // PROBLEM ADDRESSED BELOW: We need to index these by guid.
    // Unfortunately, we have a bit of a chicken and egg problem then because we can't create the tag
    // to store it in the keychain until we have the public key which we can't get until we create the
    // keypair.
    // SOLUTION:
    // 1. Create a temporary keypair using bogus tags. These are not stored in the keychain.
    // 2. generate the GUID
    // 3. add the keypair to keychain using the guid as key
    
    // Also note that this applys to all the other GNS clients as well.

    // 1. CREATE TEMPORARY KEYPAIR USING BOGUS TAGS
    
    NSData *bogusPublicTag = [@"bogus-public" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *bogusPrivateTag = [@"bogus-private" dataUsingEncoding:NSUTF8StringEncoding];

    OSStatus sanityCheck = noErr;
    
    // Container dictionaries.
    NSMutableDictionary * privateKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * publicKeyAttr = [[NSMutableDictionary alloc] init];
    NSMutableDictionary * keyPairAttr = [[NSMutableDictionary alloc] init];
    
    // Set top level dictionary for the keypair.
    [keyPairAttr setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [keyPairAttr setObject:[NSNumber numberWithUnsignedInteger:KEY_SIZE] forKey:(__bridge id)kSecAttrKeySizeInBits];
    
    // Set the private key dictionary.
    // Setting this to no makes them temporary. We don't have to delete the key because it isn't stored in the keychain.
    [privateKeyAttr setObject:[NSNumber numberWithBool:NO] forKey:(__bridge id)kSecAttrIsPermanent];
    [privateKeyAttr setObject:bogusPrivateTag forKey:(__bridge id)kSecAttrApplicationTag];
    // See SecKey.h to set other flag values.
    
    // Set the public key dictionary.
    // Setting this to no makes them temporary. We don't have to delete the key because it isn't stored in the keychain.
    [publicKeyAttr setObject:[NSNumber numberWithBool:NO] forKey:(__bridge id)kSecAttrIsPermanent];
    [publicKeyAttr setObject:bogusPublicTag forKey:(__bridge id)kSecAttrApplicationTag];
    // See SecKey.h to set other flag values.
    
    // Set attributes to top level dictionary.
    [keyPairAttr setObject:privateKeyAttr forKey:(__bridge id)kSecPrivateKeyAttrs];
    [keyPairAttr setObject:publicKeyAttr forKey:(__bridge id)kSecPublicKeyAttrs];
    
    // SecKeyGeneratePair returns the SecKeyRefs just for educational purposes.
    sanityCheck = SecKeyGeneratePair((__bridge CFDictionaryRef)keyPairAttr, &publicKey, &privateKey);
    //  LOGGING_FACILITY( sanityCheck == noErr && publicKey != NULL && privateKey != NULL, @"Something really bad went wrong with generating the key pair." );
    if(sanityCheck == noErr  && publicKey != NULL && privateKey != NULL)
    {
        if (debuggingEnabled) NSLog(@"GenerateKeyPair Successful");
    }
    
    // 2. GENERATE GUID
    
    NSString *guid = [self sha1PublicKeyToString];
    
    // 3. ADD THE KEYPAIR TO THE KEYCHAIN USING THE GUID AS A KEY
   
    NSData *publicTagCopy = [[guid stringByAppendingString:@"-public"] dataUsingEncoding:NSUTF8StringEncoding];
    NSData *privateTagCopy = [[guid stringByAppendingString:@"-private"] dataUsingEncoding:NSUTF8StringEncoding];
    
    [self insertKey:publicKey tag:publicTagCopy];
    [self insertKey:privateKey tag:privateTagCopy];
    
}

- (void)insertKey:(SecKeyRef)givenKey tag:(NSData *)tag {
    
    OSStatus sanityCheck = noErr;
    
    NSMutableDictionary * queryKey = [[NSMutableDictionary alloc] init];
    [queryKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryKey setObject:tag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    NSMutableDictionary * attributes = [queryKey mutableCopy];
    [attributes setObject:(__bridge id)givenKey forKey:(__bridge id)kSecValueRef];
    [attributes setObject:@NO forKey:(__bridge id)kSecReturnData];
    
    sanityCheck = SecItemAdd((__bridge CFDictionaryRef) attributes, NULL);
    if (sanityCheck == errSecSuccess) {
        if (debuggingEnabled) NSLog(@"insert key %@ Success", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]);
    } else {
        if (debuggingEnabled) NSLog(@"insert key %@ Failure", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]);
    }
}

- (void)deleteKey:(NSData *)tag {
    NSMutableDictionary * queryKey = [[NSMutableDictionary alloc] init];
    [queryKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryKey setObject:tag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    
    OSStatus status = SecItemDelete((__bridge CFDictionaryRef) queryKey);
    
    if (status == errSecSuccess) {
        if (debuggingEnabled) NSLog(@"delete key %@ Success", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]);
    } else {
        if (debuggingEnabled) NSLog(@"delete key %@ Failure", [[NSString alloc] initWithData:tag encoding:NSUTF8StringEncoding]);
    }
}

- (BOOL)publicKeyInKeyChain:(NSString *)guid {
    NSString *tagString = [guid stringByAppendingString:@"-public"];
    NSData *tag = [tagString dataUsingEncoding:NSUTF8StringEncoding];
    OSStatus resultCode = noErr;
    SecKeyRef publicKeyReference = NULL;
    
    NSMutableDictionary *queryPublicKey = [[NSMutableDictionary alloc] init];
    
    // Set the public key query dictionary.
    [queryPublicKey setObject:(__bridge id)kSecClassKey forKey:(__bridge id)kSecClass];
    [queryPublicKey setObject:tag forKey:(__bridge id)kSecAttrApplicationTag];
    [queryPublicKey setObject:(__bridge id)kSecAttrKeyTypeRSA forKey:(__bridge id)kSecAttrKeyType];
    [queryPublicKey setObject:[NSNumber numberWithBool:YES] forKey:(__bridge id)kSecReturnRef];
    
    // Get the key.
    resultCode = SecItemCopyMatching((__bridge CFDictionaryRef)queryPublicKey, (CFTypeRef *)&publicKeyReference);
    if (debuggingEnabled) NSLog(@"keyInKeyChain: %@ result code: %ld", guid, (long)resultCode);
    
    if (resultCode == noErr)
    {
        return true;
    } else {
        return false;
    }
}


- (NSData*)signBytesSHA256withRSA:(NSData*) plainData {
    
    size_t signedHashBytesSize = SecKeyGetBlockSize([self getPrivateKeyRef]);
    uint8_t* signedHashBytes = malloc(signedHashBytesSize);
    memset(signedHashBytes, 0x0, signedHashBytesSize);
    
    size_t hashBytesSize = CC_SHA256_DIGEST_LENGTH;
    uint8_t* hashBytes = malloc(hashBytesSize);
    if (!CC_SHA256([plainData bytes], (CC_LONG)[plainData length], hashBytes)) {
        if (hashBytes)
            free(hashBytes);
        if (signedHashBytes)
            free(signedHashBytes);
        return nil;
    }
    
    SecKeyRawSign([self getPrivateKeyRef],
                  kSecPaddingPKCS1SHA256,
                  hashBytes,
                  hashBytesSize,
                  signedHashBytes,
                  &signedHashBytesSize);
    
    NSData* signedHash = [NSData dataWithBytes:signedHashBytes
                                        length:(NSUInteger)signedHashBytesSize];
    
    if (hashBytes)
        free(hashBytes);
    if (signedHashBytes)
        free(signedHashBytes);
    
    return signedHash;
}

- (NSData*)signBytesSHA1withRSA:(NSData*) plainData {
    
    size_t signedHashBytesSize = SecKeyGetBlockSize([self getPrivateKeyRef]);
    uint8_t* signedHashBytes = malloc(signedHashBytesSize);
    memset(signedHashBytes, 0x0, signedHashBytesSize);
    
    size_t hashBytesSize = CC_SHA1_DIGEST_LENGTH;
    uint8_t* hashBytes = malloc(hashBytesSize);
    if (!CC_SHA1([plainData bytes], (CC_LONG)[plainData length], hashBytes)) {
        if (hashBytes)
            free(hashBytes);
        if (signedHashBytes)
            free(signedHashBytes);
        return nil;
    }
    
    SecKeyRawSign([self getPrivateKeyRef],
                  kSecPaddingPKCS1SHA1,
                  hashBytes,
                  hashBytesSize,
                  signedHashBytes,
                  &signedHashBytesSize);
    
    NSData* signedHash = [NSData dataWithBytes:signedHashBytes
                                        length:(NSUInteger)signedHashBytesSize];
    
    if (hashBytes)
        free(hashBytes);
    if (signedHashBytes)
        free(signedHashBytes);
    
    return signedHash;
}

- (BOOL)verifyBytesSHA1withRSA:(NSData *)plainData signature:(NSData*) signature {
    size_t signedHashBytesSize = SecKeyGetBlockSize([self getPublicKeyRef]);
    const void* signedHashBytes = [signature bytes];

    size_t hashBytesSize = CC_SHA1_DIGEST_LENGTH;
    uint8_t* hashBytes = malloc(hashBytesSize);
    if (!CC_SHA1([plainData bytes], (CC_LONG)[plainData length], hashBytes)) {
        if (hashBytes)
            free(hashBytes);
        return false;
    }
    
    OSStatus status = SecKeyRawVerify(publicKey,
                                      kSecPaddingPKCS1SHA1,
                                      hashBytes,
                                      hashBytesSize,
                                      signedHashBytes,
                                      signedHashBytesSize);
    
    if (hashBytes)
        free(hashBytes);
    
    return status == errSecSuccess;
}

size_t encodeLength(unsigned char * buf, size_t length) {
    
    // encode length in ASN.1 DER format
    if (length < 128) {
        buf[0] = length;
        return 1;
    }
    
    size_t i = (length / 256) + 1;
    buf[0] = i + 0x80;
    for (size_t j = 0 ; j < i; ++j) {         buf[i - j] = length & 0xFF;         length = length >> 8;
    }
    
    return i + 1;
}

- (NSData *) getRSAPublicKeyEncoded {
    
    NSData * publicKeyBits = [self getPublicKeyBits];
    
    // publicKeyBits is the "BITSTRING component of a full DER
    // encoded RSA public key" - we now need to build the rest
    
    static const unsigned char _encodedRSAEncryptionOID[15] = {
        
        /* Sequence of length 0xd made up of OID followed by NULL */
        0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00
        
    };
    
    unsigned char builder[15];
    NSMutableData * encKey = [[NSMutableData alloc] init];
    int bitstringEncLength;
    
    // When we get to the bitstring - how will we encode it?
    if  ([publicKeyBits length ] + 1  < 128 )
        bitstringEncLength = 1 ;
    else
        bitstringEncLength = (int)(([publicKeyBits length ] +1 ) / 256 ) + 2 ;
    
    // Overall we have a sequence of a certain length
    builder[0] = 0x30;    // ASN.1 encoding representing a SEQUENCE
    // Build up overall size made up of -
    // size of OID + size of bitstring encoding + size of actual key
    size_t i = sizeof(_encodedRSAEncryptionOID) + 2 + bitstringEncLength + [publicKeyBits length];
    size_t j = encodeLength(&builder[1], i);
    [encKey appendBytes:builder length:j +1];
    
    // First part of the sequence is the OID
    [encKey appendBytes:_encodedRSAEncryptionOID
                 length:sizeof(_encodedRSAEncryptionOID)];
    
    // Now add the bitstring
    builder[0] = 0x03;
    j = encodeLength(&builder[1], [publicKeyBits length] + 1);
    builder[j+1] = 0x00;
    [encKey appendBytes:builder length:j + 2];
    
    // Now the actual key
    [encKey appendData:publicKeyBits];
    
    return [NSData dataWithData:encKey];
}

// Generates a SHA1 hashed string from the public key encoded as HEX bytes. This is the format used for guids.
- (NSString *)sha1PublicKeyToString
{
    NSData* data = [self getRSAPublicKeyEncoded];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    
    CC_SHA1(data.bytes, (CC_LONG)data.length, digest);
    
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
    {
        // GNS uses uppercase HEX format for guids
        [output appendFormat:@"%02X", digest[i]];
    }
    
    return output;
}


/* Borrowed from:
 * https://developer.apple.com/library/mac/#documentation/security/conceptual/CertKeyTrustProgGuide/iPhone_Tasks/iPhone_Tasks.html
 */
- (void)encryptWithPublicKey:(uint8_t *)plainBuffer cipherBuffer:(uint8_t *)cipherBuffer
{
    
    if (debuggingEnabled) NSLog(@"== encryptWithPublicKey()");
    
    OSStatus status = noErr;
    
    if (debuggingEnabled) NSLog(@"** original plain text 0: %s", plainBuffer);
    
    size_t plainBufferSize = strlen((char *)plainBuffer);
    size_t cipherBufferSize = CIPHER_BUFFER_SIZE;
    
    if (debuggingEnabled) NSLog(@"SecKeyGetBlockSize() public = %lu", SecKeyGetBlockSize([self getPublicKeyRef]));
    //  Error handling
    // Encrypt using the public.
    status = SecKeyEncrypt([self getPublicKeyRef],
                           PADDING,
                           plainBuffer,
                           plainBufferSize,
                           &cipherBuffer[0],
                           &cipherBufferSize
                           );
    if (debuggingEnabled) NSLog(@"encryption result code: %ld (size: %lu)", (long)status, cipherBufferSize);
    if (debuggingEnabled) NSLog(@"encrypted text: %s", cipherBuffer);
}

- (void)decryptWithPrivateKey:(uint8_t *)cipherBuffer plainBuffer:(uint8_t *)plainBuffer
{
    OSStatus status = noErr;
    
    size_t cipherBufferSize = strlen((char *)cipherBuffer);
    
    if (debuggingEnabled) NSLog(@"decryptWithPrivateKey: length of buffer: %lu", BUFFER_SIZE);
    if (debuggingEnabled) NSLog(@"decryptWithPrivateKey: length of input: %lu", cipherBufferSize);
    
    // DECRYPTION
    size_t plainBufferSize = BUFFER_SIZE;
    
    //  Error handling
    status = SecKeyDecrypt([self getPrivateKeyRef],
                           PADDING,
                           &cipherBuffer[0],
                           cipherBufferSize,
                           &plainBuffer[0],
                           &plainBufferSize
                           );
    if (debuggingEnabled) NSLog(@"decryption result code: %ld (size: %lu)", (long)status, plainBufferSize);
    if (debuggingEnabled) NSLog(@"FINAL decrypted text: %s", plainBuffer);
    
}

- (void)testAsymmetricEncryptionAndDecryption {
    
    uint8_t *plainBuffer;
    uint8_t *cipherBuffer;
    uint8_t *decryptedBuffer;
    
    const char inputString[] = "This is a test demo for RSA Implementation in Objective C";
    int len = (int)strlen(inputString);
    // TODO: this is a hack since i know inputString length will be less than BUFFER_SIZE
    if (len > BUFFER_SIZE) len = BUFFER_SIZE-1;
    
    plainBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
    cipherBuffer = (uint8_t *)calloc(CIPHER_BUFFER_SIZE, sizeof(uint8_t));
    decryptedBuffer = (uint8_t *)calloc(BUFFER_SIZE, sizeof(uint8_t));
    
    strncpy( (char *)plainBuffer, inputString, len);
    
    NSLog(@"init() plainBuffer: %s", plainBuffer);
    //NSLog(@"init(): sizeof(plainBuffer): %d", sizeof(plainBuffer));
    [self encryptWithPublicKey:(UInt8 *)plainBuffer cipherBuffer:cipherBuffer];
    NSLog(@"encrypted data: %s", cipherBuffer);
    //NSLog(@"init(): sizeof(cipherBuffer): %d", sizeof(cipherBuffer));
    [self decryptWithPrivateKey:cipherBuffer plainBuffer:decryptedBuffer];
    NSLog(@"decrypted data: %s", decryptedBuffer);
    //NSLog(@"init(): sizeof(decryptedBuffer): %d", sizeof(decryptedBuffer));
    NSLog(@"====== /second test =======================================");
    
    free(plainBuffer);
    free(cipherBuffer);
    free(decryptedBuffer);
    
}


- (void)testAsymmetricSigningAndVerification {
    
    NSString *string = @"This is a test demo for RSA Implementation in Objective C";
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    
    NSData *signedData = [self signBytesSHA1withRSA:data];
    
    BOOL result = [self verifyBytesSHA1withRSA:data signature:signedData];
    
    if (result) {
        NSLog(@"====== SUCCESS =======================================");
    } else {
        NSLog(@"====== FAILURE =======================================");
    }
    
}

+ (void)listAllKeyChainItems {
    NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                  (__bridge id)kCFBooleanTrue, (__bridge id)kSecReturnAttributes,
                                  (__bridge id)kSecMatchLimitAll, (__bridge id)kSecMatchLimit,
                                  nil];
    
    NSArray *secItemClasses = [NSArray arrayWithObjects:
                               (__bridge id)kSecClassGenericPassword,
                               (__bridge id)kSecClassInternetPassword,
                               (__bridge id)kSecClassCertificate,
                               (__bridge id)kSecClassKey,
                               (__bridge id)kSecClassIdentity,
                               nil];
    for (id secItemClass in secItemClasses) {
        [query setObject:secItemClass forKey:(__bridge id)kSecClass];
        
        CFTypeRef result = NULL;
        OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
        if (status == errSecSuccess) {
          NSLog(@"RESULT: %@", (__bridge id)result);
//        SecItemDelete((__bridge CFDictionaryRef)query);
        }
        if (result != NULL) {
            CFRelease(result);
        }
    }
    
}

+ (void)deleteAllKeyChainItems {
    for (id secclass in @[
                          (__bridge id)kSecClassGenericPassword,
                          (__bridge id)kSecClassInternetPassword,
                          (__bridge id)kSecClassCertificate,
                          (__bridge id)kSecClassKey,
                          (__bridge id)kSecClassIdentity]) {
        NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      secclass, (__bridge id)kSecClass,
                                      nil];
        
        SecItemDelete((__bridge CFDictionaryRef)query);        
    }
}

@end
