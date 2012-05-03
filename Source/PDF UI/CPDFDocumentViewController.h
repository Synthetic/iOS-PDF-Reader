//
//  PDFReaderViewController.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFDocument;

@interface CPDFDocumentViewController : UIViewController

@property (readwrite, nonatomic, strong) CPDFDocument *document;

- (id)initWithURL:(NSURL *)inURL;

@end
