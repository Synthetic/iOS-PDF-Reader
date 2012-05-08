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

@interface CPDFDocumentViewController () <CPDFDocumentDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate, CPreviewBarDelegate, CPDFPageViewDelegate>

@property (readwrite, nonatomic, strong) UIPageViewController *pageViewController;
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
@synthesize previewScrollView = _previewScrollView;
@synthesize previewBar = _previewBar;
@synthesize chromeHidden = _chromeHidden;
@synthesize renderedPageCache = _renderedPageCache;

@synthesize document = _document;
@synthesize backgroundView = _backgroundView;

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

    NSMutableArray *theViewControllers = [NSMutableArray arrayWithObjects:
        [self pageViewControllerWithPage:[_document pageForPageNumber:1]],
        NULL
        ];
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
        {
        [theViewControllers addObject:
            [self pageViewControllerWithPage:[_document pageForPageNumber:2]]
            ];
        }
    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    [self addChildViewController:self.pageViewController];
    [self.view insertSubview:self.pageViewController.view atIndex:0];

    // #########################################################################

    CGRect theFrame = (CGRect){
        .origin = {
            .x = CGRectGetMinX(self.view.bounds),
            .y = CGRectGetMaxY(self.view.bounds) - 64,
            },
        .size = {
            .width = CGRectGetWidth(self.view.bounds),
            .height = 64,
            },
        };

    self.previewScrollView = [[CContentScrollView alloc] initWithFrame:theFrame];
    self.previewScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.previewScrollView];

    self.previewBar = [[CPreviewBar alloc] initWithFrame:(CGRect){ .size = self.previewScrollView.bounds.size } ];
    [self.previewBar addTarget:self action:@selector(gotoPage:) forControlEvents:UIControlEventValueChanged];
    self.previewBar.delegate = self;
    [self.previewBar sizeToFit];

    [self.previewScrollView addSubview:self.previewBar];
    self.previewScrollView.contentView = self.previewBar;

    // #########################################################################

    UITapGestureRecognizer *theTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:theTapGestureRecognizer];
    }

- (void)viewDidUnload
    {
    [super viewDidUnload];
    //
    self.pageViewController = NULL;
    self.previewScrollView = NULL;
    self.previewBar = NULL;
    }

- (void)viewWillAppear:(BOOL)animated
    {
    [super viewWillAppear:animated];
    //
    [self resizePageViewControllerForOrientation:self.interfaceOrientation];

    [self populateCache];
    }

- (void)viewDidAppear:(BOOL)animated
    {
    [super viewDidAppear:animated];

    [self performSelector:@selector(hideChrome) withObject:NULL afterDelay:2.0];
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
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
        self.navigationController.navigationBar.alpha = (1.0 - !self.chromeHidden);
        self.previewScrollView.alpha = (1.0 - !self.chromeHidden);
        } completion:^(BOOL finished) {
        self.chromeHidden = YES;
        }];
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
    }

- (CPDFPageViewController *)pageViewControllerWithPage:(CPDFPage *)inPage
    {
    CPDFPageViewController *thePageViewController = [[CPDFPageViewController alloc] initWithPage:inPage];
    thePageViewController.pageView.delegate = self;
    thePageViewController.pageView.renderedPageCache = self.renderedPageCache;
    return(thePageViewController);
    }

- (BOOL)openPage:(CPDFPage *)inPage
    {
    CPDFPageViewController *theCurrentPageViewController = [self.pageViewController.viewControllers objectAtIndex:0];
    if (inPage == theCurrentPageViewController.page)
        {
        return(YES);
        }

    NSMutableArray *theViewControllers = [NSMutableArray arrayWithObjects:
        [self pageViewControllerWithPage:inPage],
        NULL
        ];
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
        {
        [theViewControllers addObject:
            [self pageViewControllerWithPage:[_document pageForPageNumber:inPage.pageNumber + 1]]
            ];
        }

    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    [self updateTitle];
    [self populateCache];

    return(YES);
    }

- (void)tap:(UITapGestureRecognizer *)inRecognizer
    {
    [self toggleChrome];
    }

- (IBAction)gotoPage:(id)sender
    {
    NSUInteger thePageNumber = self.previewBar.selectedPreviewIndex + 1;

    [self openPage:[self.document pageForPageNumber:thePageNumber]];
    }

- (NSArray *)pages
    {
    return([self.pageViewController.viewControllers valueForKey:@"page"]);
    }

- (void)populateCache
    {
    NSInteger theStartPage = [[self.pages objectAtIndex:0] pageNumber];
    NSInteger theLastPage = [[self.pages lastObject] pageNumber];

    theStartPage = MAX(theStartPage - 2, 1);
    theLastPage = MIN(theLastPage + 2, self.document.numberOfPages);

    NSLog(@"(Potentially) Fetching: %d - %d", theStartPage, theLastPage);

    CGRect theBounds = [[self.pageViewController.viewControllers objectAtIndex:0] pageView].bounds;

    for (NSInteger thePageNumber = theStartPage; thePageNumber <= theLastPage; ++thePageNumber)
        {
        NSString *theKey = [NSString stringWithFormat:@"%d[%d,%d]", thePageNumber, (int)theBounds.size.width, (int)theBounds.size.height];
        if ([self.renderedPageCache objectForKey:theKey] == NULL)
            {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                UIImage *theImage = [[self.document pageForPageNumber:thePageNumber] imageWithSize:theBounds.size];
                [self.renderedPageCache setObject:theImage forKey:theKey];
                });
            }
        }
    }

#pragma mark -

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
    {
    CPDFPageViewController *theViewController = (CPDFPageViewController *)viewController;

    NSUInteger theNextPageNumber = theViewController.page.pageNumber - 1;
    if (theNextPageNumber < 1 || theNextPageNumber > self.document.numberOfPages)
        {
        return(NULL);
        }

    CPDFPage *thePage = [self.document pageForPageNumber:theNextPageNumber];
    theViewController = [self pageViewControllerWithPage:thePage];

    return(theViewController);
    }

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
    {
    CPDFPageViewController *theViewController = (CPDFPageViewController *)viewController;

    NSUInteger theNextPageNumber = theViewController.page.pageNumber + 1;
    if (theNextPageNumber < 1 || theNextPageNumber > self.document.numberOfPages)
        {
        return(NULL);
        }

    CPDFPage *thePage = [self.document pageForPageNumber:theNextPageNumber];
    theViewController = [self pageViewControllerWithPage:thePage];

    return(theViewController);
    }

#pragma mark -

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed;
    {
    [self updateTitle];
    [self populateCache];

    CPDFPageViewController *theFirstViewController = [self.pageViewController.viewControllers objectAtIndex:0];

    self.previewBar.selectedPreviewIndex = theFirstViewController.page.pageNumber - 1;
    }

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation
    {
    UIPageViewControllerSpineLocation theSpineLocation;
    NSArray *theViewControllers = NULL;

	if (UIInterfaceOrientationIsPortrait(orientation) || self.document.numberOfPages == 1)
        {
		theSpineLocation = UIPageViewControllerSpineLocationMin;

		UIViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];
		theViewControllers = [NSArray arrayWithObject:currentViewController];
        }
    else
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;

        CPDFPageViewController *currentViewController = [self.pageViewController.viewControllers objectAtIndex:0];

        NSUInteger indexOfCurrentViewController = currentViewController.page.pageNumber - 1;
        if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0)
            {
            UIViewController *nextViewController = [self pageViewController:self.pageViewController viewControllerAfterViewController:currentViewController];
            theViewControllers = [NSArray arrayWithObjects:currentViewController, nextViewController, nil];
            }
        else
            {
            UIViewController *previousViewController = [self pageViewController:self.pageViewController viewControllerBeforeViewController:currentViewController];
            theViewControllers = [NSArray arrayWithObjects:previousViewController, currentViewController, nil];
            }
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

- (BOOL)PDFPageView:(CPDFPageView *)inPageView openPage:(CPDFPage *)inPage
    {
    [self openPage:inPage];
    return(YES);
    }

@end
