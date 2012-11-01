//
//  CPDFPageView.h
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

#import <UIKit/UIKit.h>

@class CPDFPage;
@class CPDFAnnotation;
@protocol CPDFPageViewDelegate;

#pragma mark -

@interface CPDFPageView : UIView

@property (readwrite, nonatomic, strong) CPDFPage *page;
@property (readwrite, nonatomic, assign) id <CPDFPageViewDelegate> delegate;

- (CPDFAnnotation *)annotationForPoint:(CGPoint)inPoint;

@end

#pragma mark -

@protocol CPDFPageViewDelegate <NSObject>

@optional
- (BOOL)PDFPageView:(CPDFPageView *)inPageView openURL:(NSURL *)inURL fromRect:(CGRect)inFrame;
- (BOOL)PDFPageView:(CPDFPageView *)inPageView openPage:(CPDFPage *)inPage fromRect:(CGRect)inFrame;

@end
