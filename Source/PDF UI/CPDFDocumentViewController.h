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

@interface CPDFDocumentViewController : UIViewController

@property (readwrite, nonatomic, strong) CPDFDocument *document;

@property (readwrite, nonatomic, strong) IBOutlet CPagingView *pagingView;
@property (readwrite, nonatomic, strong) IBOutlet CPDFPagePlaceholderView *pagePlaceholderView;
@property (readwrite, nonatomic, strong) IBOutlet CPageControl *pageControl;
@property (readwrite, nonatomic, strong) IBOutlet UIView *chromeView;
@property (readwrite, nonatomic, strong) IBOutlet CPreviewBar *previewBar;

- (id)initWithURL:(NSURL *)inURL;

@end
