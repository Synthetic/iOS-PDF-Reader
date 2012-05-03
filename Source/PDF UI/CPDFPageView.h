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

@interface CPDFPageView : UIView

@property (readwrite, nonatomic, strong) CPDFPage *page;

- (CPDFAnnotation *)annotationForPoint:(CGPoint)inPoint;

@end
