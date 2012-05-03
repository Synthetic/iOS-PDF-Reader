//
//  CPDFAnnotationView.h
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CPDFAnnotation;

@interface CPDFAnnotationView : UIView

@property (readonly, nonatomic, strong) CPDFAnnotation *annotation;

- (id)initWithAnnotation:(CPDFAnnotation *)inAnnotation;

@end
