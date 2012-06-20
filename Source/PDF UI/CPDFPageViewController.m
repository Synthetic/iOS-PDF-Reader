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
@property (readwrite, nonatomic, strong) IBOutlet CPDFPageView *pageView;
@property (readwrite, nonatomic, strong) IBOutlet UIImageView *previewView;
@property (readwrite, nonatomic, strong) IBOutlet UIImageView *placeholderView;
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
    if (self.page != NULL)
        {
        self.previewView = [[UIImageView alloc] initWithFrame:self.view.bounds];
        self.previewView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.previewView.image = self.page.preview;
        [self.view addSubview:self.previewView];

        self.pageView = [[CPDFPageView alloc] initWithFrame:self.view.bounds];
        self.pageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.pageView.page = self.page;
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

@end
