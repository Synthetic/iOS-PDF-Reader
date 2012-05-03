//
//  PDFReaderViewController.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFDocument;
@class CPagingView;
@class CPDFPagePlaceholderView;
@class CPreviewBar;
@class CPageControl;

@interface CPDFDocumentViewController : UIPageViewController

@property (readwrite, nonatomic, strong) CPDFDocument *document;

- (id)initWithURL:(NSURL *)inURL;

@end
