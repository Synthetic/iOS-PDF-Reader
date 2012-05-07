//
//  CPDFAnnotation.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFAnnotation.h"

#import "CPDFDocument.h"
#import "PDFUtilities.h"
#import "CPDFStream.h"

@interface CPDFAnnotation ()
@property (readwrite, nonatomic, assign) CGPDFDictionaryRef dictionary;
@end

#pragma mark -

@implementation CPDFAnnotation

@synthesize subtype = _subtype;
@synthesize info = _info;
@synthesize frame = _frame;
@synthesize dictionary = _dictionary;

- (id)initWithDictionary:(CGPDFDictionaryRef)inDictionary
    {
    if ((self = [super init]) != NULL)
        {
        _dictionary = inDictionary;

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

- (CPDFStream *)stream
    {
    if ([self.subtype isEqualToString:@"RichMedia"])
        {
        NSString *theName = MyCGPDFObjectAsString(MyCGPDFDictionaryGetObjectForPath(self.dictionary, @"RichMediaContent.Assets.Names.#1.F"));
        if ([[theName pathExtension] isEqualToString:@"mov"])
            {
            CGPDFObjectRef theObject = MyCGPDFDictionaryGetObjectForPath(self.dictionary, @"RichMediaContent.Assets.Names.#1.EF.F");
            return(ConvertPDFObject(theObject));
            }
        }
    return(NULL);
    }

- (NSURL *)URL
    {
    if ([self.subtype isEqualToString:@"RichMedia"])
        {
        CGPDFObjectRef theObject = MyCGPDFDictionaryGetObjectForPath(self.dictionary, @"RichMediaContent.Configurations.#0.Instances.#0.Params.FlashVars");
        NSString *theFlashVars = MyCGPDFObjectAsString(theObject);

        NSError *theError = NULL;
        NSRegularExpression *theExpression = [NSRegularExpression regularExpressionWithPattern:@"source=((http|https)://[^&]+).+" options:0 error:&theError];

        NSTextCheckingResult *theResult = [theExpression firstMatchInString:theFlashVars options:0 range:(NSRange){ .length = theFlashVars.length }];
        if (theResult != NULL)
            {
            NSString *theURLString = [theFlashVars substringWithRange:[theResult rangeAtIndex:1]];
            NSURL *theURL = [NSURL URLWithString:theURLString];
            return(theURL);
            }
        }
    return(NULL);
    }

@end
