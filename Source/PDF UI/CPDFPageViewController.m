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
@property (readwrite, nonatomic, strong) CPDFPage *page;
@property (readwrite, nonatomic, strong) IBOutlet UIImageView *previewView;
@property (readwrite, nonatomic, strong) IBOutlet UIImageView *placeholderView;
@property (readwrite, nonatomic, strong) IBOutlet CPDFPageView *pageView;
@end

@implementation CPDFPageViewController

@synthesize previewView = _previewView;
@synthesize placeholderView = _placeholderView;
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
    [super loadView];

    if (self.page != NULL)
        {
        self.previewView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.previewView.image = self.page.preview;
        [self.view addSubview:self.previewView];

        [self.view addSubview:self.pageView];
        }
    else
        {
        self.placeholderView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.placeholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.placeholderView.image = [UIImage imageNamed:@"PagePlaceholder"];
        [self.view addSubview:self.placeholderView];
        }
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

- (NSUInteger)pageNumber
    {
    if (self.page == NULL)
        {
        return(0);
        }
    else
        {
        return(self.page.pageNumber);
        }
    }

- (CPDFPageView *)pageView
    {
    if (_pageView == NULL)
        {
        _pageView = [[CPDFPageView alloc] initWithFrame:self.view.bounds];
        _pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        }
    return(_pageView);
    }

@end
