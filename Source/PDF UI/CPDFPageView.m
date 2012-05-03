//
//  CPDFPageView.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFPageView.h"

#import "CFastTiledLayer.h"
#import "Geometry.h"
#import "CPDFPage.h"
#import "CPDFAnnotation.h"

@interface CPDFPageView () <UIGestureRecognizerDelegate>
@end

@implementation CPDFPageView

@synthesize page = _page;

//+ (Class)layerClass
//    {
//    return([CFastTiledLayer class]);
//    }

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

- (void)removeFromSuperview
    {
    [super removeFromSuperview];
    }

- (void)setPage:(CPDFPage *)inPage
    {
    if (_page != inPage)
        {
        _page = inPage;

        [self setNeedsDisplay];
        }
    }

-(void)drawRect:(CGRect)r
    {
    if (_page == NULL)
        {
        return;
        }

    CGContextRef theContext = UIGraphicsGetCurrentContext();

	CGContextSaveGState(theContext);

	// First fill the background with white.
	CGContextSetRGBFillColor(theContext, 1.0,1.0,1.0,1.0);

    CGContextSetFillColorWithColor(theContext, [[UIColor whiteColor] colorWithAlphaComponent:0.9].CGColor);
    CGContextFillRect(theContext, self.bounds);

    const CGRect theMediaBox = CGPDFPageGetBoxRect(self.page.cg, kCGPDFMediaBox);

    const CGRect theRenderRect = ScaleAndAlignRectToRect(theMediaBox, self.bounds, ImageScaling_Proportionally, ImageAlignment_Center);

	// Flip the context so that the PDF page is rendered right side up.
	CGContextTranslateCTM(theContext, 0.0, self.bounds.size.height);
	CGContextScaleCTM(theContext, 1.0, -1.0);

	// Scale the context so that the PDF page is rendered at the correct size for the zoom level.
    CGContextTranslateCTM(theContext, -(theMediaBox.origin.x - theRenderRect.origin.x), -(theMediaBox.origin.y - theRenderRect.origin.y));
	CGContextScaleCTM(theContext, theRenderRect.size.width / theMediaBox.size.width, theRenderRect.size.height / theMediaBox.size.height);

    CGContextSetFillColorWithColor(theContext, [UIColor whiteColor].CGColor);
    CGContextFillRect(theContext, theMediaBox);

	CGContextDrawPDFPage(theContext, self.page.cg);

	CGContextSetRGBStrokeColor(theContext, 1.0,0.0,0.0,1.0);
    CGContextSetLineWidth(theContext, 0.5);
    CGContextStrokeRect(theContext, CGPDFPageGetBoxRect(self.page.cg, kCGPDFCropBox));

	CGContextSetRGBStrokeColor(theContext, 0.0,1.0,0.0,1.0);
    CGContextSetLineWidth(theContext, 0.5);
    CGContextStrokeRect(theContext, CGPDFPageGetBoxRect(self.page.cg, kCGPDFBleedBox));

	CGContextSetRGBStrokeColor(theContext, 0.0,0.0,0.0,1.0);
    CGContextSetLineWidth(theContext, 0.5);
    CGContextStrokeRect(theContext, CGPDFPageGetBoxRect(self.page.cg, kCGPDFMediaBox));

//    for (CPDFAnnotation *theAnnotation in self.page.annotations)
//        {
//        CGContextStrokeRect(theContext, theAnnotation.frame);
//        }

	CGContextRestoreGState(theContext);
    }

- (BOOL)isAnnotationInteractive:(CPDFAnnotation *)inAnnotation
    {
    if ([inAnnotation.subtype isEqualToString:@"Link"] && [[inAnnotation.info objectForKey:@"S"] isEqualToString:@"URI"])
        {
        return(YES);
        }
    else
        {
        return(NO);
        }
    }

- (void)tap:(UITapGestureRecognizer *)inGestureRecognizer
    {
    CGPoint theLocation = [inGestureRecognizer locationInView:self];
    CPDFAnnotation *theAnnotation = [self annotationForPoint:theLocation];
    if (theAnnotation != NULL && [self isAnnotationInteractive:theAnnotation])
        {
        NSLog(@"Annotation tapped: %@", theAnnotation);

        NSString *theURLString = [theAnnotation.info objectForKey:@"URI"];
        if (theURLString.length > 0)
            {
            NSURL *theURL = [NSURL URLWithString:theURLString];
            if ([[UIApplication sharedApplication] canOpenURL:theURL])
                {
                [[UIApplication sharedApplication] openURL:theURL];
                }
            }
        }

    }

- (CPDFAnnotation *)annotationForPoint:(CGPoint)inPoint
    {
    const CGRect theMediaBox = CGPDFPageGetBoxRect(self.page.cg, kCGPDFMediaBox);
    const CGRect theRenderRect = ScaleAndAlignRectToRect(theMediaBox, self.bounds, ImageScaling_Proportionally, ImageAlignment_Center);
    CGAffineTransform theTransform = CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    theTransform = CGAffineTransformScale(theTransform, 1.0, -1.0);
    theTransform = CGAffineTransformTranslate(theTransform, -(theMediaBox.origin.x - theRenderRect.origin.x), -(theMediaBox.origin.y - theRenderRect.origin.y));
    theTransform = CGAffineTransformScale(theTransform, theRenderRect.size.width / theMediaBox.size.width, theRenderRect.size.height / theMediaBox.size.height);

    theTransform = CGAffineTransformInvert(theTransform);

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
