//
//  iOS-PDF-ReaderViewController.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 02/19/11.
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

#import "CPDFDocumentViewController.h"

#import <QuartzCore/QuartzCore.h>

#import "CPDFDocument.h"
#import "CPDFPageViewController.h"
#import "CPDFPage.h"
#import "CPreviewBar.h"
#import "CPDFPageView.h"
#import "CContentScrollView.h"
#import "Geometry.h"

@interface CPDFDocumentViewController () <CPDFDocumentDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate, CPreviewBarDelegate, CPDFPageViewDelegate, UIScrollViewDelegate>

@property (readwrite, nonatomic, strong) UIPageViewController *pageViewController;
@property (readwrite, nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (readwrite, nonatomic, strong) IBOutlet CPreviewBar *previewBar;
@property (readwrite, nonatomic, assign) CGRect defaultPageViewControllerFrame;

- (BOOL)canDoubleSpreadForOrientation:(UIInterfaceOrientation)inOrientation;
- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation;
- (CPDFPageViewController *)pageViewControllerWithPage:(CPDFPage *)inPage;
@end

@implementation CPDFDocumentViewController {
    NSArray *_iosSixBugFixCurrentPagesCache;
}

@synthesize pageViewController = _pageViewController;
@synthesize scrollView = _scrollView;
@synthesize previewScrollView = _previewScrollView;
@synthesize previewBar = _previewBar;
@synthesize chromeHidden = _chromeHidden;

@synthesize document = _document;
@synthesize backgroundView = _backgroundView;
@synthesize magazineMode = _magazineMode;
@synthesize pagePlaceholderImage = _pagePlaceholderImage;

- (id)initWithDocument:(CPDFDocument *)inDocument
    {
    if ((self = [super initWithNibName:NULL bundle:NULL]) != NULL)
        {
        _document = inDocument;
        _document.delegate = self;
        _maximumContentZoom = 1.0f;
        }
    return(self);
    }

- (id)initWithURL:(NSURL *)inURL;
    {
    CPDFDocument *theDocument = [[CPDFDocument alloc] initWithURL:inURL];
    return([self initWithDocument:theDocument]);
    }

- (void)didReceiveMemoryWarning
    {
    [super didReceiveMemoryWarning];
    }

#pragma mark -

- (void)setBackgroundView:(UIView *)backgroundView
    {
    if (_backgroundView != backgroundView)
        {
        [_backgroundView removeFromSuperview];

        _backgroundView = backgroundView;
        [self.view insertSubview:_backgroundView atIndex:0];
        }
    }

#pragma mark -
- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateTitle];

    // #########################################################################
    UIPageViewControllerSpineLocation theSpineLocation;
    if ([self canDoubleSpreadForOrientation:self.interfaceOrientation] == YES)
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
        }
    else
        {
        theSpineLocation = UIPageViewControllerSpineLocationMin;
        }

    // #########################################################################
    NSDictionary *theOptions = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:theSpineLocation], UIPageViewControllerOptionSpineLocationKey,
        NULL];

    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:theOptions];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;

    NSRange theRange = { .location = 1, .length = 1 };
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
        {
        theRange = (NSRange){ .location = 0, .length = 2 };
        self.pageViewController.doubleSided = YES;
        }
    NSArray *theViewControllers = [self pageViewControllersForRange:theRange];
    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    [self addChildViewController:self.pageViewController];

    if ([self respondsToSelector:@selector(automaticallyAdjustsScrollViewInsets)]) { // LEGACY iOS 6
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    self.scrollView = [[CContentScrollView alloc] initWithFrame:self.pageViewController.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.maximumZoomScale = self.maximumContentZoom;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.delegate = self;
    
    [self.scrollView addSubview:self.pageViewController.view];

    [self.view insertSubview:self.scrollView atIndex:0];
    [self.pageViewController didMoveToParentViewController:self];

    // #########################################################################

    CGRect theFrame = (CGRect){
        .origin = {
            .x = CGRectGetMinX(self.view.bounds),
            .y = CGRectGetMaxY(self.view.bounds) - 74,
            },
        .size = {
            .width = CGRectGetWidth(self.view.bounds),
            .height = 74,
            },
        };

    self.previewScrollView = [[CContentScrollView alloc] initWithFrame:theFrame];
    self.previewScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.previewScrollView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
    self.previewScrollView.contentInset = UIEdgeInsetsMake(5.0f, 0.0f, 5.0f, 0.0f);
    [self.view addSubview:self.previewScrollView];

    CGRect contentFrame = (CGRect){
        .size = {
            .width = theFrame.size.width,
            .height = 64,
            },
    };
    self.previewBar = [[CPreviewBar alloc] initWithFrame:contentFrame];
    [self.previewBar addTarget:self action:@selector(gotoPage:) forControlEvents:UIControlEventValueChanged];
    self.previewBar.delegate = self;
    [self.previewBar sizeToFit];

    [self.previewScrollView addSubview:self.previewBar];
    self.previewScrollView.contentView = self.previewBar;

    // #########################################################################

    UITapGestureRecognizer *theSingleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:theSingleTapGestureRecognizer];

    UITapGestureRecognizer *theDoubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    theDoubleTapGestureRecognizer.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:theDoubleTapGestureRecognizer];

    [theSingleTapGestureRecognizer requireGestureRecognizerToFail:theDoubleTapGestureRecognizer];
    for (UITapGestureRecognizer *tapRecognizer in self.pageViewController.gestureRecognizers)
        {
        if ([tapRecognizer isKindOfClass:[UITapGestureRecognizer class]])
            {
            [tapRecognizer requireGestureRecognizerToFail:theDoubleTapGestureRecognizer];
            }
        }
    }

- (void)viewWillAppear:(BOOL)animated
    {
    [super viewWillAppear:animated];
    //
    [self resizePageViewControllerForOrientation:self.interfaceOrientation];
    }

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self populateCache];
        [self.document startGeneratingThumbnails];
    });
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _iosSixBugFixCurrentPagesCache = [self.pages copy];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
    {
    // This is not pretty, but it does the trick for now
    [self.scrollView setZoomScale:1.0f];
    [self resizePageViewControllerForOrientation:toInterfaceOrientation];
    [self.scrollView setZoomScale:1.0f];
    
    for (UIGestureRecognizer *recognizer in self.pageViewController.gestureRecognizers)
        {
        recognizer.enabled = YES;
        }
    }

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
    {
    [self updateTitle];
    [self populateCache];
    }

- (void)setChromeHidden:(BOOL)chromeHidden {
    [self setChromeHidden:chromeHidden animated:NO afterDelay:0.0];
}

- (void)setChromeHidden:(BOOL)chromeHidden animated:(BOOL)animate {
    [self setChromeHidden:chromeHidden animated:animate afterDelay:0.0];
}

- (void)setChromeHidden:(BOOL)chromeHidden animated:(BOOL)animate afterDelay:(CGFloat)delay {
    _chromeHidden = chromeHidden;
    
    CGFloat alpha = (chromeHidden ? 0.0 : 1.0);
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration delay:delay options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.navigationController.navigationBar.alpha = alpha;
        self.previewScrollView.alpha = alpha;
    } completion:nil];
}

- (void)updateTitle
    {
    NSArray *theViewControllers = self.pageViewController.viewControllers;
    if (theViewControllers.count == 1)
        {
        CPDFPageViewController *theFirstViewController = [theViewControllers objectAtIndex:0];
        if (theFirstViewController.page.pageNumber == 1)
            {
            self.title = self.document.title;
            }
        else
            {
            self.title = [NSString stringWithFormat:@"Page %ld", (long)theFirstViewController.page.pageNumber];
            }
        }
    else if (theViewControllers.count == 2)
        {
        CPDFPageViewController *theFirstViewController = [theViewControllers objectAtIndex:0];
        if (theFirstViewController.page.pageNumber == 1)
            {
            self.title = self.document.title;
            }
        else
            {
            CPDFPageViewController *theSecondViewController = [theViewControllers objectAtIndex:1];
            self.title = [NSString stringWithFormat:@"Pages %ld-%ld", (long)theFirstViewController.page.pageNumber, (long)theSecondViewController.page.pageNumber];
            }
        }
    }

- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation
    {
    if (self.document.cg == NULL)
        {
        return;
        }

    CGRect theBounds = self.view.bounds;
    CGRect theFrame;
    CGRect theMediaBox = [self.document pageForPageNumber:1].mediaBox;
    if ([self canDoubleSpreadForOrientation:inOrientation] == YES)
        {
        theMediaBox.size.width *= 2;
        theFrame = ScaleAndAlignRectToRect(theMediaBox, theBounds, ImageScaling_Proportionally, ImageAlignment_Center);
        }
    else
        {
        theFrame = ScaleAndAlignRectToRect(theMediaBox, theBounds, ImageScaling_Proportionally, ImageAlignment_Center);
        }

    theFrame = CGRectIntegral(theFrame);

    self.defaultPageViewControllerFrame = theFrame;
    self.pageViewController.view.frame = self.defaultPageViewControllerFrame;
    
    // Show fancy shadow if PageViewController view is smaller than parent view
    if (CGRectContainsRect(self.view.frame, self.pageViewController.view.frame) && CGRectEqualToRect(self.view.frame, self.pageViewController.view.frame) == NO)
        {
            CALayer *theLayer = self.pageViewController.view.layer;
            theLayer.shadowPath = [[UIBezierPath bezierPathWithRect:self.pageViewController.view.bounds] CGPath];
            theLayer.shadowRadius = 10.0f;
            theLayer.shadowColor = [[UIColor blackColor] CGColor];
            theLayer.shadowOpacity = 0.75f;
            theLayer.shadowOffset = CGSizeZero;
        }
    else
        {
            self.pageViewController.view.layer.shadowOpacity = 0.0f;
        }
    }

#pragma mark -

- (NSArray *)pageViewControllersForRange:(NSRange)inRange
    {
    NSMutableArray *thePages = [NSMutableArray array];
    for (NSUInteger N = inRange.location; N != inRange.location + inRange.length; ++N)
        {
        CPDFPage *thePage = [self.document pageForPageNumber:N];
        [thePages addObject:[self pageViewControllerWithPage:thePage]];
        }
    return(thePages);
    }

- (BOOL)canDoubleSpreadForOrientation:(UIInterfaceOrientation)inOrientation
    {
    if (UIInterfaceOrientationIsPortrait(inOrientation) || self.document.numberOfPages == 1)
        {
        return(NO);
        }
    else
        {
        return(YES);
        }
    }

- (CPDFPageViewController *)pageViewControllerWithPage:(CPDFPage *)inPage
{
    CPDFPageViewController *thePageViewController = [[CPDFPageViewController alloc] initWithPage:inPage];
    thePageViewController.documentTitle = self.documentTitle;
    thePageViewController.pagePlaceholderImage = self.pagePlaceholderImage;
    // Force load the view.
    [thePageViewController view];
    [(CATiledLayer *)thePageViewController.pageView.layer setLevelsOfDetailBias:[self levelsOfDetailBias]];
    thePageViewController.pageView.delegate = self;
    return thePageViewController;
}

- (NSArray *)pages
    {
    return([self.pageViewController.viewControllers valueForKey:@"page"]);
    }

- (void)setMaximumContentZoom:(CGFloat)maximumContentZoom
    {
    _maximumContentZoom = maximumContentZoom;
    
    self.scrollView.maximumZoomScale = _maximumContentZoom;
    
    for (CPDFPageViewController *viewController in self.pageViewController.viewControllers)
        {
        [(CATiledLayer *)viewController.pageView.layer setLevelsOfDetailBias:[self levelsOfDetailBias]];
        }
    }

- (size_t)levelsOfDetailBias {
    return log2(self.maximumContentZoom) + 1.0f;;
}

#pragma mark -

- (BOOL)openPage:(CPDFPage *)inPage
    {
    CPDFPageViewController *theCurrentPageViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    if (inPage == theCurrentPageViewController.page)
        {
        return(YES);
        }

    NSRange theRange = { .location = inPage.pageNumber, .length = 1 };
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
        {
        if (theRange.location % 2 != 0)
            {
            // Maintain spreads as designed - first page should always be even
            theRange.location--;
            }
        theRange.length = 2;
        }
    NSArray *theViewControllers = [self pageViewControllersForRange:theRange];

    UIPageViewControllerNavigationDirection theDirection = inPage.pageNumber > theCurrentPageViewController.pageNumber ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;

    [self.scrollView setZoomScale:1.0f animated:YES];
    [self.pageViewController setViewControllers:theViewControllers direction:theDirection animated:YES completion:NULL];
    [self updateTitle];
    
    [self populateCache];

    return(YES);
    }

- (void)tap:(UITapGestureRecognizer *)inRecognizer
    {
    if (inRecognizer.state != UIGestureRecognizerStateEnded)
        {
        return;
        }
    [self setChromeHidden:!self.chromeHidden animated:YES];
    }

- (void)doubleTap:(UITapGestureRecognizer *)inRecognizer
    {
    if (inRecognizer.state != UIGestureRecognizerStateEnded)
        {
        return;
        }
//    NSLog(@"DOUBLE TAP: %f", self.scrollView.zoomScale);
    if (self.scrollView.zoomScale != 1.0)
        {
        [self.scrollView setZoomScale:1.0 animated:YES];
        }
    else
        {
        [self.scrollView setZoomScale:[UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 2.6 : 1.66 animated:YES];
        }
    }

- (IBAction)gotoPage:(id)sender
    {
    NSUInteger thePageNumber = [self.previewBar.selectedPreviewIndexes firstIndex] + 1;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
        thePageNumber = thePageNumber / 2 * 2;
        }

    NSUInteger theLength = UIInterfaceOrientationIsPortrait(self.interfaceOrientation) ? 1 : ( thePageNumber < self.document.numberOfPages ? 2 : 1 );
    self.previewBar.selectedPreviewIndexes = [NSIndexSet indexSetWithIndexesInRange:(NSRange){ .location = thePageNumber - 1, .length = theLength }];

    [self openPage:[self.document pageForPageNumber:thePageNumber]];
    }

- (void)populateCache
    {
//    NSLog(@"POPULATING CACHE")

    if (self.pages.count == 0)
        {
        return;
        }
    
    CPDFPage *theStartPage = [self.pages objectAtIndex:0] != [NSNull null] ? [self.pages objectAtIndex:0] : NULL;
    CPDFPage *theLastPage = [self.pages lastObject] != [NSNull null] ? [self.pages lastObject] : NULL;

    NSInteger theStartPageNumber = [theStartPage pageNumber];
    NSInteger theLastPageNumber = [theLastPage pageNumber];
        
    NSInteger pageSpanToLoad = 1;
    if (UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
        pageSpanToLoad = 2;
        }

    theStartPageNumber = MAX(theStartPageNumber - pageSpanToLoad, 0);
    theLastPageNumber = MIN(theLastPageNumber + pageSpanToLoad, self.document.numberOfPages);

//    NSLog(@"(Potentially) Fetching: %d - %d", theStartPageNumber, theLastPageNumber);

    UIView *thePageView = [[self.pageViewController.viewControllers objectAtIndex:0] pageView];
    if (thePageView == NULL)
        {
        NSLog(@"WARNING: No page view.");
        return;
        }
    for (NSInteger thePageNumber = theStartPageNumber; thePageNumber <= theLastPageNumber; ++thePageNumber)
        {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            CPDFPage *thePDFPage = [self.document pageForPageNumber:thePageNumber];
            [thePDFPage preview]; // Pre-load and cache the preview image
            
            dispatch_async(dispatch_get_main_queue(), ^{
                // UIKit API calls must be on main queue
                [self pageViewControllerWithPage:thePDFPage]; // Force load and cache the view controller
                });
            
            });
        }
    }

#pragma mark -

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
    {
    CPDFPageViewController *theViewController = (CPDFPageViewController *)viewController;

    NSUInteger theNextPageNumber = theViewController.page.pageNumber - 1;
    if (theNextPageNumber > self.document.numberOfPages)
        {
        return(NULL);
        }

    if (theNextPageNumber == 0 && UIInterfaceOrientationIsPortrait(self.interfaceOrientation))
        {
        return(NULL);
        }

    CPDFPage *thePage = theNextPageNumber > 0 ? [self.document pageForPageNumber:theNextPageNumber] : NULL;
    theViewController = [self pageViewControllerWithPage:thePage];

    return(theViewController);
    }

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
    {
    CPDFPageViewController *theViewController = (CPDFPageViewController *)viewController;

    NSUInteger theNextPageNumber = theViewController.page.pageNumber + 1;
    if (theNextPageNumber > self.document.numberOfPages)
        {
        return(NULL);
        }

    CPDFPage *thePage = theNextPageNumber > 0 ? [self.document pageForPageNumber:theNextPageNumber] : NULL;
    theViewController = [self pageViewControllerWithPage:thePage];

    return(theViewController);
    }

#pragma mark -

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed;
    {
    [self updateTitle];
    [self populateCache];
    [self setChromeHidden:YES animated:YES];

    CPDFPageViewController *theFirstViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    if (theFirstViewController.page)
        {
        NSArray *thePageNumbers = [self.pageViewController.viewControllers valueForKey:@"pageNumber"];
        NSMutableIndexSet *theIndexSet = [NSMutableIndexSet indexSet];
        for (NSNumber *thePageNumber in thePageNumbers)
            {
            int N = [thePageNumber intValue] - 1;
            if (N != 0)
                {
                [theIndexSet addIndex:N];
                }
            }
        self.previewBar.selectedPreviewIndexes = theIndexSet;
        }
    }

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
    {
    UIPageViewControllerSpineLocation theSpineLocation;
    NSArray *theViewControllers = nil;
    
    CPDFPageViewController *currentPageViewController = NULL;
    if (self.pageViewController.viewControllers.count > 0)
        {
        currentPageViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        if (_iosSixBugFixCurrentPagesCache && [self.pages isEqualToArray:_iosSixBugFixCurrentPagesCache] == NO)
            {
            /*
             LEGACY iOS 6 bug fix (in spineLocationForInterfaceOrientation, on iOS 6, pVG.viewControllers always returns
             what it was initialized with rather than the true current view controllers (most often this means it returns
             pages 0 and 1, or page 1). We cache what the true value is in the iOSSixBugFix ivar so we can catch this and
             rotate to the proper pages.
             */
            NSLog(@"Performing iOS 6 bug fix to rotate to the proper spread...");
            currentPageViewController = [self pageViewControllerWithPage:[_iosSixBugFixCurrentPagesCache objectAtIndex:0]];
            }
        else if (currentPageViewController.pageNumber == 0 && self.pageViewController.viewControllers.count == 2)
            {
            // Don't transition into the placeholder page if viewing spread
            currentPageViewController = [self.pageViewController.viewControllers objectAtIndex:1];
            }
        }
    else
        {
        // No current view controllers, initialize with first page
        currentPageViewController = [self pageViewControllerWithPage:[self.document pageForPageNumber:1]];
        }

    if (UIInterfaceOrientationIsPortrait(orientation) || self.document.numberOfPages == 1)
        {
		theSpineLocation = UIPageViewControllerSpineLocationMin;
        self.pageViewController.doubleSided = NO;
        if (self.pageViewController.viewControllers.count != 1)
            {
            theViewControllers = @[currentPageViewController];
            }
        }
    else
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
        self.pageViewController.doubleSided = YES;
        
        if (self.pageViewController.viewControllers.count != 2)
            {
            NSUInteger theCurrentPageNumber = currentPageViewController.page.pageNumber;
            
            if (theCurrentPageNumber % 2 != 0)
                {
                // Page is odd, alloc the view controller before it (to maintain spreads)
                CPDFPageViewController *thePriorViewController = [self pageViewControllerWithPage:[self.document pageForPageNumber:theCurrentPageNumber - 1]];
                theViewControllers = @[thePriorViewController, currentPageViewController];
                }
            else
                {
                // Page is even, alloc the view controller after it
                CPDFPageViewController *theNextViewController = [self pageViewControllerWithPage:[self.document pageForPageNumber:theCurrentPageNumber + 1]];
                theViewControllers = @[currentPageViewController, theNextViewController];
                }
            }
        }
    
    if (theViewControllers)
        {
        // Only change the view controllers if necessary (better performance)
        [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
        }
    
    return(theSpineLocation);
    }

#pragma mark -

- (NSInteger)numberOfPreviewsInPreviewBar:(CPreviewBar *)inPreviewBar
    {
    return(self.document.numberOfPages);
    }

- (UIImage *)previewBar:(CPreviewBar *)inPreviewBar previewAtIndex:(NSInteger)inIndex;
    {
    CPDFPage *thePage = [self.document pageForPageNumber:inIndex + 1];
    UIImage *theImage = nil;
    if (thePage.thumbnailExists)
        {
        theImage = thePage.thumbnail;
        }
    return(theImage);
    }

#pragma mark -

- (void)PDFDocument:(CPDFDocument *)inDocument didUpdateThumbnailForPage:(CPDFPage *)inPage
    {
    [self.previewBar updatePreviewAtIndex:inPage.pageNumber - 1];
    }

#pragma mark -

- (BOOL)PDFPageView:(CPDFPageView *)inPageView openPage:(CPDFPage *)inPage fromRect:(CGRect)inFrame
    {
    [self openPage:inPage];
    return(YES);
    }

#pragma mark -

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;     // return a view that will be scaled. if delegate returns nil, nothing happens
    {
    return(self.pageViewController.view);
    }

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
    {
    CGFloat originX = (scrollView.contentSize.width * 0.5f);
    CGFloat originY = (scrollView.contentSize.height * 0.5f);
    if (scrollView.contentSize.width < scrollView.frame.size.width)
        {
        originX += ((scrollView.frame.size.width - scrollView.contentSize.width) / 2.0f);
        }
    if (scrollView.contentSize.height < scrollView.frame.size.height)
        {
        originY += ((scrollView.frame.size.height - scrollView.contentSize.height) / 2.0f);
        }
    self.pageViewController.view.center = CGPointMake(originX, originY);
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale
    {
    scrollView.scrollEnabled = YES;
    scrollView.pinchGestureRecognizer.enabled = YES;
    
    BOOL zoomAtNormal = (scrollView.zoomScale == 1.0f);
    if (zoomAtNormal)
        {
        [self resizePageViewControllerForOrientation:self.interfaceOrientation];
        }
    else
        {
        self.pageViewController.view.frame = CGRectIntegral(self.pageViewController.view.frame);
        }
    
    for (UIGestureRecognizer *recognizer in self.pageViewController.gestureRecognizers)
        {
        recognizer.enabled = zoomAtNormal;
        }
    }

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
    {
    if (scrollView.zoomScale > 1.0f && scrollView.dragging)
        {
        CGFloat threshold = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? -90.0f : -50.0f);
        BOOL shouldZoomOut = NO;
        if (scrollView.contentOffset.x < threshold || scrollView.contentOffset.y < threshold)
            {
            // Snap zoom out if user drags beyond the top / left
            shouldZoomOut = YES;
            }
        else
            {
            // Snap zoom out if user drags beyond the bottom / right
            CGFloat xExtremityDrag = scrollView.contentSize.width - scrollView.frame.size.width - scrollView.contentOffset.x;
            CGFloat yExtremityDrag = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y;
            shouldZoomOut = (xExtremityDrag < threshold || yExtremityDrag < threshold);
            }
        
        if (shouldZoomOut)
            {
            [scrollView setZoomScale:1.0f animated:YES];
            scrollView.scrollEnabled = NO; // Prevents an unfortunate UI 'snapping' animation that would occur after the drag ends
            scrollView.pinchGestureRecognizer.enabled = NO;
            }
        }
    }

@end
