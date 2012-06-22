//
//  CPDFPageViewController.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright 2012 Jonathan Wight. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of Jonathan Wight.

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
