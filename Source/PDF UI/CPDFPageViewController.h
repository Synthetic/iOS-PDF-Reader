//
//  CPDFPageViewController.h
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFPage;
@class CPDFPageView;

@interface CPDFPageViewController : UIViewController

@property (readonly, nonatomic, strong) CPDFPage *page;
@property (readonly, nonatomic, strong) IBOutlet CPDFPageView *pageView;

- (id)initWithPage:(CPDFPage *)inPage;

@end
