//
//  CPDFAnnotationView.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFAnnotationView.h"

#import "CPDFAnnotation.h"

@implementation CPDFAnnotationView

@synthesize annotation = _annotation;

- (id)initWithAnnotation:(CPDFAnnotation *)inAnnotation;
    {
    if ((self = [super initWithFrame:inAnnotation.frame]) != NULL)
        {
        _annotation = inAnnotation;
        }
    return(self);
    }


@end
