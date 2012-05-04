//
//  CPDFPageViewController.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFPageViewController.h"

#import "CPDFPageView.h"
#import "CPDFDocument.h"
#import "CPDFPage.h"

@interface CPDFPageViewController ()
@property (readwrite, nonatomic, strong) IBOutlet CPDFPageView *pageView;
@property (readwrite, nonatomic, strong) CPDFPage *page;
@end

@implementation CPDFPageViewController

@synthesize pageView = _pageView;
@synthesize page = _page;

- (id)initWithPage:(CPDFPage *)inPage;
    {
    if ((self = [super initWithNibName:NULL bundle:NULL]) != NULL)
        {
        _page = inPage;
        }
    return self;
    }

- (void)viewDidLoad
    {
    [super viewDidLoad];
    //
    self.pageView.page = self.page;
    }

- (void)loadView
    {
    self.pageView = [[CPDFPageView alloc] init];
    self.view = self.pageView;
    }

- (void)viewDidUnload
    {
    [super viewDidUnload];

    self.pageView = NULL;
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

@end
