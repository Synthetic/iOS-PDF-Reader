//
//  PDFReaderViewController.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

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
@property (readwrite, nonatomic, strong) IBOutlet CContentScrollView *scrollView;
@property (readwrite, nonatomic, strong) IBOutlet CContentScrollView *previewScrollView;
@property (readwrite, nonatomic, strong) IBOutlet CPreviewBar *previewBar;
@property (readwrite, nonatomic, assign) BOOL chromeHidden;
@property (readwrite, nonatomic, strong) NSCache *renderedPageCache;

- (void)hideChrome;
- (void)toggleChrome;
- (BOOL)canDoubleSpreadForOrientation:(UIInterfaceOrientation)inOrientation;
- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation;
- (CPDFPageViewController *)pageViewControllerWithPage:(CPDFPage *)inPage;
@end

@implementation CPDFDocumentViewController

@synthesize pageViewController = _pageViewController;
@synthesize scrollView = _scrollView;
@synthesize previewScrollView = _previewScrollView;
@synthesize previewBar = _previewBar;
@synthesize chromeHidden = _chromeHidden;
@synthesize renderedPageCache = _renderedPageCache;

@synthesize document = _document;
@synthesize backgroundView = _backgroundView;
@synthesize magazineMode = _magazineMode;

- (id)initWithDocument:(CPDFDocument *)inDocument
    {
    if ((self = [super initWithNibName:NULL bundle:NULL]) != NULL)
        {
        _document = inDocument;
        _document.delegate = self;
        _renderedPageCache = [[NSCache alloc] init];
        _renderedPageCache.countLimit = 8;
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

- (void)loadView
    {
    [super loadView];

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
        }
    NSArray *theViewControllers = [self pageViewControllersForRange:theRange];
    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    [self addChildViewController:self.pageViewController];

    self.scrollView = [[CContentScrollView alloc] initWithFrame:self.pageViewController.view.bounds];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.scrollView.contentView = self.pageViewController.view;
    self.scrollView.maximumZoomScale = [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone ? 8.0 : 4.0;
    self.scrollView.delegate = self;
    
    [self.scrollView addSubview:self.scrollView.contentView];

    [self.view insertSubview:self.scrollView atIndex:0];

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
    }

- (void)viewWillAppear:(BOOL)animated
    {
    [super viewWillAppear:animated];
    //
    [self resizePageViewControllerForOrientation:self.interfaceOrientation];

    double delayInSeconds = 1.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self populateCache];
        [self.document startGeneratingThumbnails];
        });
    }

- (void)viewDidAppear:(BOOL)animated
    {
    [super viewDidAppear:animated];

    [self performSelector:@selector(hideChrome) withObject:NULL afterDelay:0.5];
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
    {
    [self resizePageViewControllerForOrientation:toInterfaceOrientation];
    }

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
    {
    [self updateTitle];
    [self.renderedPageCache removeAllObjects];
    [self populateCache];
    }

- (void)hideChrome
    {
        if (self.chromeHidden == NO)
            {
            [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
                self.navigationController.navigationBar.alpha = 0.0;
                self.previewScrollView.alpha = 0.0;
                } completion:^(BOOL finished) {
                self.chromeHidden = YES;
                }];
            }
    }

- (void)toggleChrome
    {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        self.navigationController.navigationBar.alpha = (1.0 - !self.chromeHidden);
        self.previewScrollView.alpha = (1.0 - !self.chromeHidden);
        } completion:^(BOOL finished) {
        self.chromeHidden = !self.chromeHidden;
        }];
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
            self.title = [NSString stringWithFormat:@"Page %d", theFirstViewController.page.pageNumber];
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
            self.title = [NSString stringWithFormat:@"Pages %d-%d", theFirstViewController.page.pageNumber, theSecondViewController.page.pageNumber];
            }
        }
    }

- (void)resizePageViewControllerForOrientation:(UIInterfaceOrientation)inOrientation
    {
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

    self.pageViewController.view.frame = theFrame;
    
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
        CPDFPage *thePage = N > 0 ? [self.document pageForPageNumber:N] : NULL;
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
    // Force load the view.
    [thePageViewController view];
//    NSParameterAssert(thePageViewController.pageView != NULL);
    thePageViewController.pageView.delegate = self;
    thePageViewController.pageView.renderedPageCache = self.renderedPageCache;
    return(thePageViewController);
    }

- (NSArray *)pages
    {
    return([self.pageViewController.viewControllers valueForKey:@"page"]);
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
        theRange.length = 2;
        }
    NSArray *theViewControllers = [self pageViewControllersForRange:theRange];

    UIPageViewControllerNavigationDirection theDirection = inPage.pageNumber > theCurrentPageViewController.pageNumber ? UIPageViewControllerNavigationDirectionForward : UIPageViewControllerNavigationDirectionReverse;

    [self.pageViewController setViewControllers:theViewControllers direction:theDirection animated:YES completion:NULL];
    [self updateTitle];
    
    [self populateCache];

    return(YES);
    }

- (void)tap:(UITapGestureRecognizer *)inRecognizer
    {
    [self toggleChrome];
    }

- (void)doubleTap:(UITapGestureRecognizer *)inRecognizer
    {
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
    NSParameterAssert(thePageView != NULL);
    CGRect theBounds = thePageView.bounds;

    for (NSInteger thePageNumber = theStartPageNumber; thePageNumber <= theLastPageNumber; ++thePageNumber)
        {
        NSString *theKey = [NSString stringWithFormat:@"%d[%d,%d]", thePageNumber, (int)theBounds.size.width, (int)theBounds.size.height];
        if ([self.renderedPageCache objectForKey:theKey] == NULL)
            {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
                UIImage *theImage = [[self.document pageForPageNumber:thePageNumber] imageWithSize:theBounds.size scale:[UIScreen mainScreen].scale];
                if (theImage != NULL)
                    {
                    [self.renderedPageCache setObject:theImage forKey:theKey];
                    }
                });
            }
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
    [self hideChrome];

    CPDFPageViewController *theFirstViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    if (theFirstViewController.page)
        {
        NSArray *thePageNumbers = [self.pageViewController.viewControllers valueForKey:@"pageNumber"];
        NSMutableIndexSet *theIndexSet = [NSMutableIndexSet indexSet];
        for (NSNumber *thePageNumber in thePageNumbers)
            {
            int N = [thePageNumber integerValue] - 1;
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
    NSArray *theViewControllers = NULL;

	if (UIInterfaceOrientationIsPortrait(orientation) || self.document.numberOfPages == 1)
        {
		theSpineLocation = UIPageViewControllerSpineLocationMin;
        self.pageViewController.doubleSided = NO;

        CPDFPageViewController *theCurrentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        if (theCurrentViewController.page == NULL)
            {
            theViewControllers = [self pageViewControllersForRange:(NSRange){ 1, 1 }];
            }
        else
            {
            theViewControllers = [self pageViewControllersForRange:(NSRange){ theCurrentViewController.page.pageNumber, 1 }];
            }
        }
    else
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
        self.pageViewController.doubleSided = YES;

        CPDFPageViewController *theCurrentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
        NSUInteger theCurrentPageNumber = theCurrentViewController.page.pageNumber;

        theCurrentPageNumber = theCurrentPageNumber / 2 * 2;

        theViewControllers = [self pageViewControllersForRange:(NSRange){ theCurrentPageNumber, 2 }];
        }

    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    return(theSpineLocation);
    }

#pragma mark -

- (NSInteger)numberOfPreviewsInPreviewBar:(CPreviewBar *)inPreviewBar
    {
    return(self.document.numberOfPages);
    }

- (UIImage *)previewBar:(CPreviewBar *)inPreviewBar previewAtIndex:(NSInteger)inIndex;
    {
    UIImage *theImage = [self.document pageForPageNumber:inIndex + 1].thumbnail;
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


@end
