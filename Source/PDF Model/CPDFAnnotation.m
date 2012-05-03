//
//  CPDFAnnotation.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFAnnotation.h"

#import "CPDFDocument.h"

@interface CPDFAnnotation ()
@end

#pragma mark -

@implementation CPDFAnnotation

- (id)initWithDictionary:(CGPDFDictionaryRef)inDictionary
    {
    if ((self = [super init]) != NULL)
        {
//        CGPDFDictionaryApplyBlock(inDictionary, ^(const char *key, CGPDFObjectRef value) {
//            NSLog(@"%s: %@", key, ConvertPDFObject(value));
//            });

        CGPDFObjectRef theObject;
        CGPDFDictionaryGetObject(inDictionary, "Subtype", &theObject);
        _subtype = ConvertPDFObject(theObject);

        CGPDFDictionaryGetObject(inDictionary, "Rect", &theObject);
        NSArray *theRectArray = ConvertPDFObject(theObject);
        _frame = (CGRect){
            .origin = {
                .x = [[theRectArray objectAtIndex:0] floatValue],
                .y = [[theRectArray objectAtIndex:1] floatValue],
                },
            .size = {
                .width = [[theRectArray objectAtIndex:2] floatValue] - [[theRectArray objectAtIndex:0] floatValue],
                .height = [[theRectArray objectAtIndex:3] floatValue] - [[theRectArray objectAtIndex:1] floatValue],
                },
            };

        CGPDFDictionaryGetObject(inDictionary, "A", &theObject);
        _info = ConvertPDFObject(theObject);

        }
    return self;
    }

- (NSString *)description
    {
    return([NSString stringWithFormat:@"%@ (%@, %@, %@)", [super description], self.subtype, NSStringFromCGRect(self.frame), self.info]);
    }


@end
