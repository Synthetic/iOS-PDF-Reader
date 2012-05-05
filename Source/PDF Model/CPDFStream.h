//
//  CPDFStream.h
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPDFStream : NSObject

@property (readonly, nonatomic, assign) CGPDFStreamRef stream;

- (id)initWithStream:(CGPDFStreamRef)inStream;

- (NSURL *)fileURLWithPathExtension:(NSString *)inPathExtension;

@end
