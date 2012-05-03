//
//  CPDFPageViewController.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFPageViewController.h"

#import "CPDFPageView.h"

@interface CPDFPageViewController ()
@property (readwrite, nonatomic, strong) IBOutlet CPDFPageView *pageView;
@property (readwrite, nonatomic, strong) CPDFPage *page;
@end

@implementation CPDFPageViewController

- (id)initWithPage:(CPDFPage *)inPage;
    {
    if ((self = [super initWithNibName:NSStringFromClass([self class]) bundle:NULL]) != NULL)
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

- (void)viewDidUnload
    {
    [super viewDidUnload];
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

@end
