//
//  CPDFDocument_Private.h
//  PDFReader
//
//  Created by Jonathan Wight on 06/01/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFDocument.h"

@class CPersistentCache;

@interface CPDFDocument (CPDFDocument_Private)

@property (readonly, nonatomic, retain) CPersistentCache *cache;

@end
