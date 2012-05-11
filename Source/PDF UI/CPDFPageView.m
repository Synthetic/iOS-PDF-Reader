//
//  CPDFPageView.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFPageView.h"

#import "Geometry.h"
#import "CPDFPage.h"
#import "CPDFAnnotation.h"
#import "CPDFDocument.h"
#import "CPDFAnnotationView.h"

@interface CPDFPageView () <UIGestureRecognizerDelegate>
- (CGAffineTransform)transform;
- (void)addAnnotationViews;
@end

#pragma mark -

@implementation CPDFPageView

@synthesize delegate = _delegate;
@synthesize page = _page;
@synthesize renderedPageCache = _renderedPageCache;

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;

//        self.layer.borderColor = [UIColor purpleColor].CGColor;
//        self.layer.borderWidth = 2.0;

        UITapGestureRecognizer *theTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        theTapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:theTapGestureRecognizer];

        self.userInteractionEnabled = YES;
        }
    return(self);
    }

- (id)initWithFrame:(CGRect)inFrame
    {
    if ((self = [super initWithFrame:inFrame]) != NULL)
        {
        self.contentMode = UIViewContentModeRedraw;

//        self.layer.borderColor = [UIColor purpleColor].CGColor;
//        self.layer.borderWidth = 2.0;

        UITapGestureRecognizer *theTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
        theTapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:theTapGestureRecognizer];

        self.userInteractionEnabled = YES;
        }
    return(self);
    }

- (void)setPage:(CPDFPage *)inPage
    {
    if (_page != inPage)
        {
        _page = inPage;

        [self addAnnotationViews];

        [self setNeedsDisplay];
        }
    }

-(void)drawRect:(CGRect)r
    {
    if (_page == NULL)
        {
        NSLog(@"FOO: %@", [UIImage imageNamed:@"EmptyPage.png"]);
        [[UIImage imageNamed:@"EmptyPage.png"] drawInRect:self.bounds];
        return;
        }

    CGContextRef theContext = UIGraphicsGetCurrentContext();

    CGContextSaveGState(theContext);

    // First fill the background with white.
    CGContextSetRGBFillColor(theContext, 1.0,1.0,1.0,1.0);
    CGContextSetFillColorWithColor(theContext, [[UIColor whiteColor] colorWithAlphaComponent:0.9].CGColor);
    CGContextFillRect(theContext, self.bounds);

    const CGRect theMediaBox = CGRectApplyAffineTransform(self.page.mediaBox, CGAffineTransformInvert([self transform]));

    CGContextSetFillColorWithColor(theContext, [UIColor whiteColor].CGColor);
    CGContextFillRect(theContext, theMediaBox);

    UIImage *theCachedImage = [self.renderedPageCache objectForKey:[NSString stringWithFormat:@"%d[%d,%d]", self.page.pageNumber, (int)self.bounds.size.width, (int)self.bounds.size.height]];
    if (theCachedImage != NULL)
        {
        [theCachedImage drawInRect:self.bounds];
        }
    else
        {
        CGAffineTransform theTransform = [self transform];
        CGContextConcatCTM(theContext, theTransform);

        CGContextDrawPDFPage(theContext, self.page.cg);
        }

#if 0
	CGContextSetRGBStrokeColor(theContext, 1.0,0.0,0.0,1.0);
    CGContextSetLineWidth(theContext, 0.5);
    CGContextStrokeRect(theContext, CGPDFPageGetBoxRect(self.page.cg, kCGPDFCropBox));

	CGContextSetRGBStrokeColor(theContext, 0.0,1.0,0.0,1.0);
    CGContextSetLineWidth(theContext, 0.5);
    CGContextStrokeRect(theContext, CGPDFPageGetBoxRect(self.page.cg, kCGPDFBleedBox));

	CGContextSetRGBStrokeColor(theContext, 0.0,0.0,0.0,1.0);
    CGContextSetLineWidth(theContext, 0.5);
    CGContextStrokeRect(theContext, CGPDFPageGetBoxRect(self.page.cg, kCGPDFMediaBox));
#endif

#if 0
	CGContextSetRGBStrokeColor(theContext, 1.0,0.0,0.0,1.0);
    for (CPDFAnnotation *theAnnotation in self.page.annotations)
        {
        CGContextStrokeRect(theContext, theAnnotation.frame);
        }

#endif

    CGContextRestoreGState(theContext);
    }

#pragma marl -

- (BOOL)isAnnotationInteractive:(CPDFAnnotation *)inAnnotation
    {
    if ([inAnnotation.subtype isEqualToString:@"Link"])
        {
        if ([[inAnnotation.info objectForKey:@"S"] isEqualToString:@"URI"])
            {
            return(YES);
            }
        else if ([[inAnnotation.info objectForKey:@"S"] isEqualToString:@"GoTo"])
            {
            return(YES);
            }
        }
    return(NO);
    }

- (CPDFAnnotation *)annotationForPoint:(CGPoint)inPoint
    {
    CGAffineTransform theTransform = CGAffineTransformInvert([self transform]);

    inPoint = CGPointApplyAffineTransform(inPoint, theTransform);

    for (CPDFAnnotation *theAnnotation in self.page.annotations)
        {
        if (CGRectContainsPoint(theAnnotation.frame, inPoint))
            {
            return(theAnnotation);
            }
        }

    return(NULL);
    }

#pragma mark -

- (void)layoutSubviews
    {
    for (CPDFAnnotationView *theAnnotationView in self.subviews)
        {
        CPDFAnnotation *theAnnotation = theAnnotationView.annotation;
        theAnnotationView.frame = CGRectApplyAffineTransform(theAnnotation.frame, [self transform]);
        }
    }

- (CGAffineTransform)transform
    {
    const CGRect theMediaBox = self.page.mediaBox;
    const CGRect theRenderRect = ScaleAndAlignRectToRect(theMediaBox, self.bounds, ImageScaling_Proportionally, ImageAlignment_Center);
    CGAffineTransform theTransform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    theTransform = CGAffineTransformScale(theTransform, 1.0, -1.0);
    theTransform = CGAffineTransformTranslate(theTransform, -(theMediaBox.origin.x - theRenderRect.origin.x), -(theMediaBox.origin.y - theRenderRect.origin.y));
    theTransform = CGAffineTransformScale(theTransform, theRenderRect.size.width / theMediaBox.size.width, theRenderRect.size.height / theMediaBox.size.height);
    return(theTransform);
    }

- (void)addAnnotationViews
    {
    for (CPDFAnnotation *theAnnotation in self.page.annotations)
        {
        if ([theAnnotation.subtype isEqualToString:@"RichMedia"])
            {
            CPDFAnnotationView *theAnnotationView = [[CPDFAnnotationView alloc] initWithAnnotation:theAnnotation];
            [self addSubview:theAnnotationView];
            }
        }
    }

#pragma mark -

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];
    CPDFAnnotation *theAnnotation = [self annotationForPoint:theLocation];
    if (theAnnotation != NULL && [self isAnnotationInteractive:theAnnotation])
        {
        NSString *theType = [theAnnotation.info objectForKey:@"S"];

        if ([theType isEqualToString:@"URI"])
            {
            NSString *theURLString = [theAnnotation.info objectForKey:@"URI"];
            if (theURLString.length > 0)
                {
                NSURL *theURL = [NSURL URLWithString:theURLString];

                if ([self.delegate respondsToSelector:@selector(PDFPageView:openURL:)])
                    {
                    [self.delegate PDFPageView:self openURL:theURL];
                    }
                else
                    {
                    if ([[UIApplication sharedApplication] canOpenURL:theURL])
                        {
                        [[UIApplication sharedApplication] openURL:theURL];
                        }
                    }
                }
            }
        else if ([theType isEqualToString:@"GoTo"])
            {
            NSString *thePageName = [theAnnotation.info objectForKey:@"D"];

            CPDFPage *thePage = [self.page.document pageForPageName:thePageName];
            if ([self.delegate respondsToSelector:@selector(PDFPageView:openPage:)])
                {
                [self.delegate PDFPageView:self openPage:thePage];
                }
            }
        else
            {
            NSLog(@"Unknown annotation tapped: %@", theAnnotation);
            }
        }
    }

#pragma mark -

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
    {
//    NSLog(@"%@ %@", gestureRecognizer, otherGestureRecognizer);
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]])
        {
        CGPoint theLocation = [gestureRecognizer locationInView:self];
        CPDFAnnotation *theAnnotation =[self annotationForPoint:theLocation];
        if (theAnnotation != NULL && [self isAnnotationInteractive:theAnnotation])
            {
            return(NO);
            }
        }
    return(YES);
    }

@end
