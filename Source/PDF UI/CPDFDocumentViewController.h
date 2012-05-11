//
//  PDFReaderViewController.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFDocument;
@class CContentScrollView;
@class CPreviewBar;

@interface CPDFDocumentViewController : UIViewController

@property (readwrite, nonatomic, strong) CPDFDocument *document;

@property (readonly, nonatomic, strong) UIPageViewController *pageViewController;
@property (readonly, nonatomic, strong) IBOutlet CContentScrollView *previewScrollView;
@property (readonly, nonatomic, strong) IBOutlet CPreviewBar *previewBar;
@property (readwrite, nonatomic, strong) UIView *backgroundView;
@property (readwrite, nonatomic, assign) BOOL magazineMode;

- (id)initWithURL:(NSURL *)inURL;

@end
