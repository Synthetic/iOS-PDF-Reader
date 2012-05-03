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

@property (readwrite, nonatomic, strong) CPreviewBar *previewBar;
@end

@implementation CPDFDocumentViewController

@synthesize document = _document;

- (id)initWithURL:(NSURL *)inURL;
    {
    CPDFDocument *theDocument = [[CPDFDocument alloc] initWithURL:inURL];
    UIPageViewControllerSpineLocation theSpineLocation = UIPageViewControllerSpineLocationMin;
    if (theDocument.numberOfPages > 1 && UIInterfaceOrientationIsLandscape([UIDevice currentDevice].orientation))
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;
        }
    NSDictionary *theOptions = [NSDictionary dictionaryWithObjectsAndKeys:
        [NSNumber numberWithInt:theSpineLocation], UIPageViewControllerOptionSpineLocationKey,
        NULL];

	if ((self = [self initWithTransitionStyle:UIPageViewControllerTransitionStylePageCurl navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:theOptions]) != NULL)
		{
        self.dataSource = self;
        self.delegate = self;

        _document = theDocument;
        _document.delegate = self;

        NSMutableArray *theViewControllers = [NSMutableArray arrayWithObjects:
            [[CPDFPageViewController alloc] initWithPage:[_document pageForPageNumber:1]],
            NULL
            ];
        if (self.spineLocation == UIPageViewControllerSpineLocationMid)
            {
            [theViewControllers addObject:
                [[CPDFPageViewController alloc] initWithPage:[_document pageForPageNumber:2]]
                ];
            }
        [self setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:NULL];
        }
	return(self);
    }

- (void)didReceiveMemoryWarning
    {
    [super didReceiveMemoryWarning];
    }

#pragma mark - View lifecycle

- (void)loadView
    {
    [super loadView];

    CGRect theBounds = self.view.bounds;

    self.previewBar = [[CPreviewBar alloc] initWithFrame:(CGRect){ .size = { 1024, 64 } }];
    self.previewBar.delegate = self;
    [self.previewBar sizeToFit];

    CGRect theFrame = {
        .origin = {
            .x = CGRectGetMinY(theBounds),
            .y = CGRectGetMaxY(theBounds) - 64,
            },
        .size = {
            .width = CGRectGetWidth(theBounds),
            .height = 64,
            }
        };

    CContentScrollView *theScrollView = [[CContentScrollView alloc] initWithFrame:theFrame];
    theScrollView.contentView = self.previewBar;
    theScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    theScrollView.layer.zPosition = -1;
    [self.view addSubview:theScrollView];

    UITapGestureRecognizer *theTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
//    theTapGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:theTapGestureRecognizer];
    }

- (void)viewDidLoad
    {
    [super viewDidLoad];
    //
    }

- (void)viewDidUnload
    {
    [super viewDidUnload];
    }

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
    {
    return(YES);
    }

- (void)tap:(UITapGestureRecognizer *)inRecognizer
    {
    [self.navigationController setNavigationBarHidden:!self.navigationController.navigationBarHidden animated:YES];
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

- (UIPageViewControllerSpineLocation)pageViewController:(UIPageViewController *)pageViewController spineLocationForInterfaceOrientation:(UIInterfaceOrientation)orientation;
    {
    UIPageViewControllerSpineLocation theSpineLocation;
    NSArray *theViewControllers = NULL;

	if (UIInterfaceOrientationIsPortrait(orientation) || self.document.numberOfPages == 1)
        {
		theSpineLocation = UIPageViewControllerSpineLocationMin;

		UIViewController *currentViewController = [self.viewControllers objectAtIndex:0];
		theViewControllers = [NSArray arrayWithObject:currentViewController];
        }
    else
        {
        theSpineLocation = UIPageViewControllerSpineLocationMid;

        CPDFPageViewController *currentViewController = [self.viewControllers objectAtIndex:0];

        NSUInteger indexOfCurrentViewController = currentViewController.page.pageNumber - 1;
        if (indexOfCurrentViewController == 0 || indexOfCurrentViewController % 2 == 0)
            {
            UIViewController *nextViewController = [self pageViewController:self viewControllerAfterViewController:currentViewController];
            theViewControllers = [NSArray arrayWithObjects:currentViewController, nextViewController, nil];
            }
        else
            {
            UIViewController *previousViewController = [self pageViewController:self viewControllerBeforeViewController:currentViewController];
            theViewControllers = [NSArray arrayWithObjects:previousViewController, currentViewController, nil];
            }
        }

//    NSLog(@"%d %@", theSpineLocation, theViewControllers);

    [self setViewControllers:theViewControllers direction:UIPageViewControllerNavigationDirectionForward animated:YES completion:NULL];
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

//- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
//    {
//    NSLog(@"%@", self.gestureRecognizers);
//
////    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
////        {
////        return(YES);
////        }
//    return(NO);
//    }

@end
