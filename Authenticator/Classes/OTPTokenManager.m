//
//  OTPTokenManager.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OTPTokenManager.h"
@import OneTimePasswordLegacy;


static NSString *const kOTPKeychainEntriesArray = @"OTPKeychainEntries";


@implementation OTPTokenManager

- (NSArray *)tokens
{
    return self.mutableTokens;
}

+ (NSArray<OTPToken *> *)tokenList
{
    NSMutableArray *mutableTokens = [NSMutableArray array];
    // Fetch tokens in the order they were saved in User Defaults
    NSArray *keychainReferences = [self keychainRefList];
    if (keychainReferences) {
        for (NSData *keychainItemRef in keychainReferences) {
            OTPToken *token = [OTPToken tokenWithKeychainItemRef:keychainItemRef];
            if (token) [mutableTokens addObject:token];
        }
    }
    return [mutableTokens copy];
}

- (void)fetchTokensFromKeychain
{
    NSArray *tokens = [self.class tokenList];
    NSArray *recoveredTokens = [self.class recoverLostTokens:tokens];
    NSArray *allTokens = [tokens arrayByAddingObjectsFromArray:recoveredTokens];
    self.mutableTokens = [allTokens mutableCopy];

    if (recoveredTokens.count) {
        // If lost tokens were found and appended, save the full list of tokens
        NSArray *keychainReferences = [self.tokens valueForKey:@"keychainItemRef"];
        [self.class setKeychainRefList:keychainReferences];
    }
}

+ (NSArray<OTPToken *> *)recoverLostTokens:(NSArray<OTPToken *> *)knownTokens
{
    NSMutableArray *recoveredTokens = [NSMutableArray new];
    // Fetch all tokens from keychain and append any which weren't in the saved ordering
    NSArray *allTokens = [OTPToken allTokensInKeychain];
    for (OTPToken *token in allTokens) {
        NSUInteger indexOfTokenWithSameKeychainItemRef = [knownTokens indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if ([obj isKindOfClass:[OTPToken class]] &&
                [((OTPToken *)obj).keychainItemRef isEqual:token.keychainItemRef]) {
                return YES;
            }
            return NO;
        }];

        if (indexOfTokenWithSameKeychainItemRef == NSNotFound) {
            [recoveredTokens addObject:token];
        }
    }
    return [recoveredTokens copy];
}


+ (NSArray<NSData *> *)keychainRefList {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kOTPKeychainEntriesArray];
}

+ (BOOL)setKeychainRefList:(NSArray<NSData *> *)keychainReferences
{
    [[NSUserDefaults standardUserDefaults] setObject:keychainReferences forKey:kOTPKeychainEntriesArray];
    return [[NSUserDefaults standardUserDefaults] synchronize];
}

@end
