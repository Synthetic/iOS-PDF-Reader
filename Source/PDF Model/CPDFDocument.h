//
//  CPDFDocument.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CPDFDocumentDelegate;

@class CPDFPage;

@interface CPDFDocument : NSObject

@property (readonly, nonatomic, strong) NSURL *URL;
@property (readonly, nonatomic, assign) CGPDFDocumentRef cg;
@property (readonly, nonatomic, assign) NSUInteger numberOfPages;
@property (readwrite, nonatomic, weak) id <CPDFDocumentDelegate> delegate;

@property (readonly, nonatomic, strong) NSString *title;

- (id)initWithURL:(NSURL *)inURL;

- (CPDFPage *)pageForPageNumber:(NSInteger)inPageNumber;
@end

#pragma mark -

@protocol CPDFDocumentDelegate <NSObject>

@optional
- (void)PDFDocument:(CPDFDocument *)inDocument didUpdateThumbnailForPage:(CPDFPage *)inPage;
@end
