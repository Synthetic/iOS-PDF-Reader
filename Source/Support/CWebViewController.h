//
//  CWebViewController.h
//  SnapMagazine
//
//  Created by Jonathan Wight on 6/20/12.
//  Copyright (c) 2012 Synthetic. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CWebViewController : UIViewController

@property (readonly, nonatomic, strong) UIWebView *webView;

- (id)initWithURL:(NSURL *)inURL;

@end
