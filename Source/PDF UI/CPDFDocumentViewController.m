//
//  PDFReaderViewController.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFDocumentViewController.h"

#import "CPDFDocument.h"
#import "CPDFPageViewController.h"
#import "CPDFPage.h"
#import "CPreviewBar.h"
#import "CPDFPageView.h"
#import "CContentScrollView.h"
#import <QuartzCore/QuartzCore.h>

@interface CPDFDocumentViewController () <CPDFDocumentDelegate, UIPageViewControllerDelegate, UIPageViewControllerDataSource, UIGestureRecognizerDelegate, CPreviewBarDelegate>

@property (readwrite, nonatomic, strong) UIPageViewController *pageViewController;
@property (readwrite, nonatomic, strong) IBOutlet CPreviewBar *previewBar;
@property (readwrite, nonatomic, assign) BOOL chromeHidden;
@end

@implementation CPDFDocumentViewController

@synthesize pageViewController = _pageViewController;
@synthesize previewBar = _previewBar;
@synthesize chromeHidden = _chromeHidden;

@synthesize document = _document;

- (id)initWithDocument:(CPDFDocument *)inDocument
    {
    if ((self = [super initWithNibName:@"CPDFDocumentViewController" bundle:NULL]) != NULL)
        {
        _document = inDocument;
        _document.delegate = self;
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

#pragma mark - View lifecycle

- (void)viewDidLoad
    {
    [super viewDidLoad];

    [self updateTitle];

    self.previewBar.delegate = self;
    [self.previewBar sizeToFit];

    UIPageViewControllerSpineLocation theSpineLocation = UIPageViewControllerSpineLocationMin;
    if (_document.numberOfPages > 1 && UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation))
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
        }
    NSDictionary *theOptions = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:theSpineLocation], UIPageViewControllerOptionSpineLocationKey,
        NULL];

    self.pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:theOptions];
    self.pageViewController.delegate = self;
    self.pageViewController.dataSource = self;
    [self addChildViewController:self.pageViewController];
    self.pageViewController.view.frame = self.view.bounds;
    [self.view insertSubview:self.pageViewController.view atIndex:0];

    NSMutableArray *theViewControllers = [NSMutableArray arrayWithObjects:
        [[CPDFPageViewController alloc] initWithPage:[_document pageForPageNumber:1]],
        NULL
        ];
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
        {
        [theViewControllers addObject:
            [[CPDFPageViewController alloc] initWithPage:[_document pageForPageNumber:2]]
            ];
        }
    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];

    UITapGestureRecognizer *theTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    [self.view addGestureRecognizer:theTapGestureRecognizer];
    }

- (void)viewDidUnload
    {
    [super viewDidUnload];
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

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
    {
    [self updateTitle];
    }

- (void)hideChrome
    {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
//        [self.navigationController setNavigationBarHidden:theFlag animated:YES];
        self.navigationController.navigationBar.alpha = (1.0 - !self.chromeHidden);
        self.previewBar.alpha = (1.0 - !self.chromeHidden);
        } completion:^(BOOL finished) {
        self.chromeHidden = YES;
        }];
    }

- (void)toggleChrome
    {
    [UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
//        [self.navigationController setNavigationBarHidden:theFlag animated:YES];
        self.navigationController.navigationBar.alpha = (1.0 - !self.chromeHidden);
        self.previewBar.alpha = (1.0 - !self.chromeHidden);
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

- (void)tap:(UITapGestureRecognizer *)inRecognizer
    {
    [self toggleChrome];
    }

- (IBAction)gotoPage:(id)sender
    {
    NSUInteger thePageNumber = self.previewBar.selectedPreviewIndex + 1;

    NSMutableArray *theViewControllers = [NSMutableArray arrayWithObjects:
        [[CPDFPageViewController alloc] initWithPage:[_document pageForPageNumber:thePageNumber]],
        NULL
        ];
    if (self.pageViewController.spineLocation == UIPageViewControllerSpineLocationMid)
        {
        [theViewControllers addObject:
            [[CPDFPageViewController alloc] initWithPage:[_document pageForPageNumber:thePageNumber + 1]]
            ];
        }

    [self.pageViewController setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
    [self updateTitle];
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
    theViewController = [[CPDFPageViewController alloc] initWithPage:thePage];

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
    theViewController = [[CPDFPageViewController alloc] initWithPage:thePage];

    return(theViewController);
    }

#pragma mark -

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray *)previousViewControllers transitionCompleted:(BOOL)completed;
    {
    [self updateTitle];
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

//    NSLog(@"%d %@", theSpineLocation, theViewControllers);

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

@end
