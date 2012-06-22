//
//  CPDFStream.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright 2012 Jonathan Wight. All rights reserved.
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
//  THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of Jonathan Wight.

#import "CPDFStream.h"

@implementation CPDFStream

@synthesize stream = _stream;

- (id)initWithStream:(CGPDFStreamRef)inStream
    {
    if ((self = [super init]) != NULL)
        {
        _stream = inStream;
        }
    return self;
    }

- (NSString *)description
    {
    CGPDFDataFormat theFormat;
    NSData *theData = (__bridge_transfer NSData *)CGPDFStreamCopyData(_stream, &theFormat);
    return([NSString stringWithFormat:@"%@ (format: %d, length: %d)", [super description], theFormat, theData.length]);
    }

- (NSData *)data
    {
    CGPDFDataFormat theFormat;
    NSData *theData = (__bridge_transfer NSData *)CGPDFStreamCopyData(_stream, &theFormat);
    return(theData);
    }

- (NSURL *)fileURLWithPathExtension:(NSString *)inPathExtension
    {
    NSString *thePath = [[NSTemporaryDirectory() stringByAppendingPathComponent:@"XXXXXXXXXXXXXXXX"] stringByAppendingPathExtension:inPathExtension];
    size_t theBufferLength = strlen([thePath UTF8String]) + 1;
    char thePathBuffer[theBufferLength];
    strncpy(thePathBuffer, [thePath UTF8String], theBufferLength);
    int theFileDescriptor = mkstemps(thePathBuffer, inPathExtension.length + 1);

    NSData *theData = self.data;
    write(theFileDescriptor, theData.bytes, inPathExtension.length + 1);
    close(theFileDescriptor);

    NSURL *theURL = NULL;

    theURL = [NSURL fileURLWithPath:[NSString stringWithUTF8String:thePathBuffer]];

    return(theURL);
    }

@end
