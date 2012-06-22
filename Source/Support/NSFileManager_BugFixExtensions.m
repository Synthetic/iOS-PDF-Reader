//
//  NSFileManager_BugFixExtensions.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 06/01/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY TOXICSOFTWARE.COM ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL TOXICSOFTWARE.COM OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of toxicsoftware.com.

#import "NSFileManager_BugFixExtensions.h"

@interface CBlockEnumerator : NSEnumerator
@property (readwrite, nonatomic, copy) id (^block)(void);
@end

#pragma mark -

@implementation NSFileManager (NSFileManager_BugFixExtensions)

- (NSEnumerator *)tx_enumeratorAtURL:(NSURL *)url includingPropertiesForKeys:(NSArray *)keys options:(NSDirectoryEnumerationOptions)mask errorHandler:(BOOL (^)(NSURL *url, NSError *error))handler;
    {
    NSAssert(mask == 0, @"We don't handle masks");
    NSAssert(keys == NULL, @"We don't handle non-null keys");
    
    NSDirectoryEnumerator *theInnerEnumerator = [self enumeratorAtPath:[url path]];

    CBlockEnumerator *theEnumerator = [[CBlockEnumerator alloc] init];
    theEnumerator.block = ^id(void) {
        NSString *thePath = [theInnerEnumerator nextObject];
        if (thePath != NULL)
            {
            return([url URLByAppendingPathComponent:thePath]);
            }
        else
            {
            return(NULL);
            }
         };
    
    return(theEnumerator);
    }

@end

#pragma mark -

@implementation CBlockEnumerator

@synthesize block = _block;

- (id)nextObject
    {
    id theObject = self.block();
    return(theObject);
    }

@end
