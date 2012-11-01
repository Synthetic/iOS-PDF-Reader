//
//  CWebViewController.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 6/20/12.
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

#import "CWebViewController.h"

@interface CWebViewController () <UIWebViewDelegate>
@property (readwrite, nonatomic, strong) NSURL *URL;
@property (readwrite, nonatomic, strong) UIWebView *webView;
@property (readonly, nonatomic, strong) UIActivityIndicatorView *loadingIndicatorView;
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
        _webView.delegate = self;
        _loadingIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_webView addSubview:_loadingIndicatorView];
        _loadingIndicatorView.center = CGPointMake(_webView.frame.size.width/2, _webView.frame.size.height/2);
        _loadingIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin;

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

- (void)webViewDidStartLoad:(UIWebView *)webView
    {
    [_loadingIndicatorView startAnimating];
    }

- (void)webViewDidFinishLoad:(UIWebView *)webView
    {
    [_loadingIndicatorView stopAnimating];
    }

@end
