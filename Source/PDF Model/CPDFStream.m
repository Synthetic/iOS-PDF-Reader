//
//  CPDFStream.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFStream.h"

@implementation CPDFStream

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
