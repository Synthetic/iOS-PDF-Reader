//
//  CPreviewBar.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 02/20/11.
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

#import "CPreviewBar.h"

#import <QuartzCore/QuartzCore.h>

@interface CPreviewBar ()
- (void)setup;
@end

#pragma mark -

@implementation CPreviewBar

@synthesize highlightColor = _highlightColor;
@synthesize selectedPreviewIndexes = _selectedPreviewIndexes;
@synthesize previewSize = _previewSize;
@synthesize previewGap = _previewGap;
@synthesize placeholderImage = _placeholderImage;
@synthesize delegate = _delegate;

- (id)initWithCoder:(NSCoder *)inCoder
    {
    if ((self = [super initWithCoder:inCoder]) != NULL)
        {
        [self setup];
        }
    return(self);
    }

- (id)initWithFrame:(CGRect)frame
    {
    if ((self = [super initWithFrame:frame]) != NULL)
        {
        [self setup];
        }
    return(self);
    }

- (void)setup
    {

    self.highlightColor = [UIColor redColor];

    self.previewSize = (CGSize){ self.frame.size.height, self.frame.size.height };
    self.previewGap = 4.0;

    UIGraphicsBeginImageContextWithOptions(self.previewSize, NO, 1.0);

    CGContextRef theContext = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(theContext, [UIColor clearColor].CGColor);
    CGContextFillRect(theContext, (CGRect){ .size = self.previewSize });

    self.placeholderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    self.opaque = NO;

    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    }

- (void)setSelectedPreviewIndexes:(NSIndexSet *)inIndexSet
    {
    if (_selectedPreviewIndexes != inIndexSet)
        {
        [CATransaction begin];

        [_selectedPreviewIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CALayer *theLayer = [self.layer.sublayers objectAtIndex:idx];
            theLayer.borderWidth = 0.0;
            }];


        _selectedPreviewIndexes = inIndexSet;

        [_selectedPreviewIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
            CALayer *theLayer = [self.layer.sublayers objectAtIndex:idx];
            theLayer.borderColor = self.highlightColor.CGColor;
            theLayer.borderWidth = 5.0;
            }];

        [CATransaction commit];
        }
    }

- (void)setDelegate:(id<CPreviewBarDelegate>)inDelegate
    {
    if (_delegate != inDelegate)
        {
        _delegate = inDelegate;

        [self setNeedsLayout];
        }
    }

- (CGSize)sizeThatFits:(CGSize)inSize
    {
    NSInteger N = [self.delegate numberOfPreviewsInPreviewBar:self];
    N = MAX(N, 1);
    CGSize theSize = (CGSize){ self.previewSize.width * N + self.previewGap * (N - 1), self.previewSize.height };
    return(theSize);
    }

- (void)layoutSubviews
    {
    NSInteger theCount = [self.delegate numberOfPreviewsInPreviewBar:self];
    for (NSUInteger N = 0; N != theCount; ++N)
        {
        CALayer *theLayer = [CALayer layer];
        theLayer.bounds = (CGRect){ .size = self.previewSize };
        theLayer.position = (CGPoint){ .x = N * (self.previewSize.width + self.previewGap), .y = 0 };
//        theLayer.borderColor = [UIColor greenColor].CGColor;
//        theLayer.borderWidth = 1.0;
//        theLayer.backgroundColor = [UIColor whiteColor].CGColor;
        theLayer.anchorPoint = CGPointZero;
        [theLayer setValue:[NSNumber numberWithUnsignedInteger:N] forKey:@"previewIndex"];

        UIImage *theImage = [self.delegate previewBar:self previewAtIndex:N];
        if (theImage)
            {
            theLayer.contents = (id)theImage.CGImage;
            }
        else
            {
            theLayer.contents = (id)self.placeholderImage.CGImage;
            }

        [self.layer addSublayer:theLayer];
        }
    }

- (void)tap:(UIGestureRecognizer *)inSender
    {
    CGPoint theLocation = [inSender locationInView:self];
    CALayer *theLayer = [self.layer hitTest:theLocation];
    NSUInteger thePreviewIndex = [[theLayer valueForKey:@"previewIndex"] unsignedIntegerValue];
    self.selectedPreviewIndexes = [NSIndexSet indexSetWithIndex:thePreviewIndex];
    [self sendActionsForControlEvents:UIControlEventValueChanged];
    }

- (void)updatePreviewAtIndex:(NSInteger)inIndex;
    {
    CALayer *theLayer = [self.layer.sublayers objectAtIndex:inIndex];
    UIImage *theImage = [self.delegate previewBar:self previewAtIndex:inIndex];
    if (theImage)
        {
        theLayer.contents = (id)theImage.CGImage;
        }
    }

@end
