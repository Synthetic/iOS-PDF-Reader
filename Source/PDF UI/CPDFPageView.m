//
//  CPDFPageView.m
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

#import "CPDFPageView.h"

#import <QuartzCore/QuartzCore.h>

#import "Geometry.h"
#import "CPDFPage.h"
#import "CPDFAnnotation.h"
#import "CPDFDocument.h"
#import "CPDFAnnotationView.h"
#import "CFadelessTiledLayer.h"

@interface CPDFPageView () <UIGestureRecognizerDelegate>
- (CGAffineTransform)PDFTransform;
- (void)addAnnotationViews;
@end

#pragma mark -

@implementation CPDFPageView

@synthesize delegate = _delegate;
@synthesize page = _page;

+ (Class)layerClass {
    return [CATiledLayer class];
}

- (void)_initialize {
    self.contentMode = UIViewContentModeRedraw;
    
    self.backgroundColor = [UIColor blackColor];
    self.opaque = YES;
    
    CATiledLayer *tiledLayer = (CATiledLayer *)self.layer;
    tiledLayer.levelsOfDetail = 0; // Don't make any tiles for zooming out
    tiledLayer.tileSize = CGSizeMake(1024.0f, 1024.0f);
    
    UITapGestureRecognizer *theTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)];
    theTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:theTapGestureRecognizer];
    
    self.opaque = YES;
    self.userInteractionEnabled = YES;
}

- (id)initWithCoder:(NSCoder *)inCoder {
    self = [super initWithCoder:inCoder];
    if (self) {
		[self _initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)inFrame {
    self = [super initWithFrame:inFrame];
    if (self) {
        [self _initialize];
    }
    return self;
}

- (void)setPage:(CPDFPage *)inPage {
    if (_page != inPage) {
        _page = inPage;
        [self addAnnotationViews];
        [self setNeedsDisplay];
    }
}

- (void)drawLayer:(CALayer*)layer inContext:(CGContextRef)context {
    // Fill the background with white.
    CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
    CGContextFillRect(context, self.bounds);
    
    CGContextSaveGState(context);
    // Flip the context so that the PDF page is rendered right side up.
    CGContextTranslateCTM(context, 0.0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // Scale the context so that the PDF page is rendered at the correct size for the zoom level.
    CGRect pageRect = CGPDFPageGetBoxRect(self.page.cg, kCGPDFMediaBox);
    CGFloat pdfScale = self.frame.size.width/pageRect.size.width;
    CGContextScaleCTM(context, pdfScale, pdfScale);
    CGContextDrawPDFPage(context, self.page.cg);
    CGContextRestoreGState(context);
}

- (void)didMoveToWindow
	{
    self.contentScaleFactor = 1.0; // Don't render unnecessary tile sizes http://markpospesel.wordpress.com/2012/04/03/on-the-importance-of-setting-contentscalefactor-in-catiledlayer-backed-views/
	}


#pragma mark -

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
    CGAffineTransform theTransform = CGAffineTransformInvert([self PDFTransform]);

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
        theAnnotationView.frame = CGRectApplyAffineTransform(theAnnotation.frame, [self PDFTransform]);
        }
    }

- (CGAffineTransform)PDFTransform
    {
    const CGRect theMediaBox = self.page.mediaBox;
    CGRect theRenderRect = ScaleAndAlignRectToRect(theMediaBox, self.bounds, ImageScaling_Proportionally, ImageAlignment_Center);
    theRenderRect = CGRectIntegral(theRenderRect);
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

                if ([self.delegate respondsToSelector:@selector(PDFPageView:openURL:fromRect:)])
                    {
                    CGRect theAnnotationFrame = theAnnotation.frame;
                    theAnnotationFrame = CGRectApplyAffineTransform(theAnnotationFrame, self.PDFTransform);
                    [self.delegate PDFPageView:self openURL:theURL fromRect:theAnnotationFrame];
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
            if (thePage == NULL)
                {
                NSLog(@"Error: Cannot find page with name %@", thePageName);
                }
            else
                {
                if ([self.delegate respondsToSelector:@selector(PDFPageView:openPage:fromRect:)])
                    {
                    CGRect theAnnotationFrame = theAnnotation.frame;
                    theAnnotationFrame = CGRectApplyAffineTransform(theAnnotationFrame, self.PDFTransform);
                    [self.delegate PDFPageView:self openPage:thePage fromRect:theAnnotationFrame];
                    }
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
