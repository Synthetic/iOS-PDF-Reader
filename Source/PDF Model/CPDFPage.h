//
//  CPDFPage.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/20/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CPDFDocument;

@interface CPDFPage : NSObject

@property (readonly, nonatomic, weak) CPDFDocument *document;
@property (readonly, nonatomic, assign) NSInteger pageNumber;
@property (readonly, nonatomic, assign) CGPDFPageRef cg;
@property (readonly, nonatomic, strong) NSArray *annotations;
@property (readonly, nonatomic, assign) CGRect mediaBox;

- (id)initWithDocument:(CPDFDocument *)inDocument pageNumber:(NSInteger)inPageNumber;

- (UIImage *)image;
- (UIImage *)imageWithSize:(CGSize)inSize;

- (UIImage *)thumbnail;

@end
