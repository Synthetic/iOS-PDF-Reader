//
//  CPDFDocument.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFDocument.h"

#import "CPDFDocument_Private.h"
#import "CPDFPage.h"
#import "CPersistentCache.h"

static void MyCGPDFDictionaryApplierFunction(const char *key, CGPDFObjectRef value, void *info);

@interface CPDFDocument ()
@property (readwrite, assign) dispatch_queue_t queue;

- (void)startGeneratingThumbnails;
@end

#pragma mark -

@implementation CPDFDocument

@synthesize URL = _URL;
@synthesize cg = _cg;
@synthesize delegate = _delegate;

@synthesize queue = _queue;

- (id)initWithURL:(NSURL *)inURL;
	{
	if ((self = [super init]) != NULL)
		{
        _URL = inURL;

        _cg = CGPDFDocumentCreateWithURL((__bridge CFURLRef)inURL);

        [self startGeneratingThumbnails];
		}
	return(self);
	}

- (void)dealloc
    {
    if (_queue != NULL)
        {
        dispatch_release(_queue);
        _queue = NULL;
        }

    if (_cg)
        {
        CGPDFDocumentRelease(_cg);
        _cg = NULL;
        }
    }

- (NSUInteger)numberOfPages
    {
    return(CGPDFDocumentGetNumberOfPages(self.cg));
    }

- (NSString *)title
    {
    CGPDFDictionaryRef theInfo = CGPDFDocumentGetInfo(self.cg);
    CGPDFStringRef thePDFTitle = NULL;
    CGPDFDictionaryGetString(theInfo, "Title", &thePDFTitle);
    NSString *theTitle = (__bridge_transfer NSString *)CGPDFStringCopyTextString(thePDFTitle);
    return(theTitle);
    }

#pragma mark -

- (CPDFPage *)pageForPageNumber:(NSInteger)inPageNumber
    {
    NSString *theKey = [NSString stringWithFormat:@"page_%d", inPageNumber];
    CPDFPage *thePage = [self.cache objectForKey:theKey];
    if (thePage == NULL)
        {
        thePage = [[CPDFPage alloc] initWithDocument:self pageNumber:inPageNumber];
        [self.cache setObject:thePage forKey:theKey];
        }
    return(thePage);
    }

- (void)startGeneratingThumbnails
    {
    const size_t theNumberOfPages = CGPDFDocumentGetNumberOfPages(self.cg);

    self.queue = dispatch_queue_create("com.example.MyQueue", NULL);

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^(void) {

        dispatch_apply(theNumberOfPages, self.queue, ^(size_t inIndex) {

            const size_t thePageNumber = inIndex + 1;

            CPDFPage *thePage = [self pageForPageNumber:thePageNumber];

            NSString *theKey = [NSString stringWithFormat:@"page_%zd_image_128x128", thePageNumber];
            if ([self.cache objectForKey:theKey] == NULL)
                {
                UIImage *theImage = [thePage imageWithSize:(CGSize){ 128, 128 }];
                [self.cache setObject:theImage forKey:theKey];
                }

            dispatch_async(dispatch_get_main_queue(), ^(void) {
                if ([self.delegate respondsToSelector:@selector(PDFDocument:didUpdateThumbnailForPage:)])
                    {
                    [self.delegate PDFDocument:self didUpdateThumbnailForPage:thePage];
                    }
                });
            });
        });
    }

- (void)stopGeneratingThumbnails
    {
    }


@end

id ConvertPDFObject(CGPDFObjectRef inObject)
    {
    id theResult = NULL;
    const CGPDFObjectType theType = CGPDFObjectGetType(inObject);
    switch (CGPDFObjectGetType(inObject))
        {
        case kCGPDFObjectTypeNull:
            {
            theResult = [NSNull null];
            }
            break;
        case kCGPDFObjectTypeBoolean:
            {
            CGPDFBoolean theValue;
            CGPDFObjectGetValue(inObject, theType, &theValue);
            theResult = [NSNumber numberWithBool:theValue];
            }
            break;
        case kCGPDFObjectTypeInteger:
            {
            CGPDFInteger theValue;
            CGPDFObjectGetValue(inObject, theType, &theValue);
            theResult = [NSNumber numberWithLong:theValue];
            }
            break;
        case kCGPDFObjectTypeReal:
            {
            CGPDFReal theValue;
            CGPDFObjectGetValue(inObject, theType, &theValue);
            theResult = [NSNumber numberWithDouble:theValue];
            }
            break;
        case kCGPDFObjectTypeName:
            {
            const char *theValue;
            CGPDFObjectGetValue(inObject, theType, &theValue);
            return([NSString stringWithUTF8String:theValue]);
            }
            break;
        case kCGPDFObjectTypeString:
            {
            CGPDFStringRef theValue = NULL;
            CGPDFObjectGetValue(inObject, theType, &theValue);
            theResult = (__bridge_transfer NSString *)CGPDFStringCopyTextString(theValue);
            }
            break;
        case kCGPDFObjectTypeArray:
            {
            CGPDFArrayRef theValue = NULL;
            CGPDFObjectGetValue(inObject, theType, &theValue);

            size_t theCount = CGPDFArrayGetCount(theValue);
            NSMutableArray *theArray = [NSMutableArray array];
            for (size_t N = 0; N != theCount; ++N)
                {
                CGPDFObjectRef thePDFObject;
                CGPDFArrayGetObject(theValue, N, &thePDFObject);
                id theObject = ConvertPDFObject(thePDFObject);
                if (theObject == NULL)
                    {
                    NSLog(@"Cannot convert object of type: %d", CGPDFObjectGetType(thePDFObject));
                    }
                else
                    {
                    [theArray addObject:theObject];
                    }
                }
            theResult = theArray;
            }
            break;
        case kCGPDFObjectTypeDictionary:
            {
            CGPDFDictionaryRef theValue = NULL;
            CGPDFObjectGetValue(inObject, theType, &theValue);

            NSMutableDictionary *theDictionary = [NSMutableDictionary dictionary];

            CGPDFDictionaryApplyBlock(theValue, ^(const char *key, CGPDFObjectRef value) {
                NSString *theKey = [NSString stringWithUTF8String:key];
                if ([theKey isEqualToString:@"Parent"])
                    {
                    return;
                    }
                id theObject = NULL;

                    {
                    theObject = ConvertPDFObject(value);
                    }
                if (theObject == NULL)
                    {
                    NSLog(@"Could not process: %@", theKey);
                    return;
                    }
                [theDictionary setObject:theObject forKey:theKey];
                });
            theResult = theDictionary;
            }
            break;
        case kCGPDFObjectTypeStream:
            break;
        }
    return(theResult);
    }


void CGPDFDictionaryApplyBlock(CGPDFDictionaryRef inDictionary, void (^inBlock)(const char *key, CGPDFObjectRef value))
    {
    CGPDFDictionaryApplyFunction(inDictionary, MyCGPDFDictionaryApplierFunction, (__bridge void *)inBlock);
    }

static void MyCGPDFDictionaryApplierFunction(const char *key, CGPDFObjectRef value, void *info)
    {
    void (^theBlock)(const char *key, CGPDFObjectRef value) = (__bridge void (^)(const char *, CGPDFObjectRef ))info;
    theBlock(key, value);
    }
