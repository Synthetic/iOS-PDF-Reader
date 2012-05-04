//
//  CPDFPageView.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

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
- (BOOL)PDFPageView:(CPDFPageView *)inPageView openURL:(NSURL *)inURL;
- (BOOL)PDFPageView:(CPDFPageView *)inPageView openPage:(CPDFPage *)inPage;

@end
