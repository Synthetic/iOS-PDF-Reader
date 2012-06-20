//
//  CWebViewController.m
//  SnapMagazine
//
//  Created by Jonathan Wight on 6/20/12.
//  Copyright (c) 2012 Synthetic. All rights reserved.
//

#import "CWebViewController.h"

@interface CWebViewController ()
@property (readwrite, nonatomic, strong) NSURL *URL;
@property (readwrite, nonatomic, strong) UIWebView *webView;
@end

@implementation CWebViewController

@synthesize URL = _URL;
@synthesize webView = _webView;

- (id)initWithURL:(NSURL *)inURL
    {
    if ((self = [super initWithNibName:NULL bundle:NULL]) != NULL)
        {
        _URL = inURL;

        _webView = [[UIWebView alloc] initWithFrame:(CGRect){ .size = { 320, 320 } }];
        NSURLRequest *theRequest = [NSURLRequest requestWithURL:_URL];
        [_webView loadRequest:theRequest];
        }
    return(self);
    }

- (void)loadView
    {
    self.view = self.webView;
    }

- (void)didReceiveMemoryWarning
    {
    [super didReceiveMemoryWarning];
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

@end
