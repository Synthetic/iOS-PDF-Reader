//
//  CPDFAnnotation.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 5/3/12.
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
        _subtype = TXConvertPDFObject(theObject);

        CGPDFDictionaryGetObject(inDictionary, "Rect", &theObject);
        NSArray *theRectArray = TXConvertPDFObject(theObject);
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
        _info = TXConvertPDFObject(theObject);
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
        NSString *theName = TXCGPDFObjectAsString(TXCGPDFDictionaryGetObjectForPath(self.dictionary, @"RichMediaContent.Assets.Names.#1.F"));
        if ([[theName pathExtension] isEqualToString:@"mov"])
            {
            CGPDFObjectRef theObject = TXCGPDFDictionaryGetObjectForPath(self.dictionary, @"RichMediaContent.Assets.Names.#1.EF.F");
            return(TXConvertPDFObject(theObject));
            }
        }
    return(NULL);
    }

- (NSURL *)URL
    {
    if ([self.subtype isEqualToString:@"RichMedia"])
        {
        CGPDFObjectRef theObject = TXCGPDFDictionaryGetObjectForPath(self.dictionary, @"RichMediaContent.Configurations.#0.Instances.#0.Params.FlashVars");
        NSString *theFlashVars = TXCGPDFObjectAsString(theObject);

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
