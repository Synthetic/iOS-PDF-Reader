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
#import "PDFUtilities.h"

@interface CPDFDocument ()
@property (readwrite, nonatomic, assign) dispatch_queue_t queue;
@property (readwrite, nonatomic, strong) NSDictionary *pageNumbersByName;

- (void)startGeneratingThumbnails;
@end

#pragma mark -

@implementation CPDFDocument

@synthesize URL = _URL;
@synthesize cg = _cg;
@synthesize delegate = _delegate;

@synthesize queue = _queue;
@synthesize pageNumbersByName = _pageNumbersByName;

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

#pragma mark -

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id __unsafe_unretained [])buffer count:(NSUInteger)len
	{
    NSUInteger theStartIndex = state->state;
    NSUInteger theEndIndex = MIN(state->state + len, self.numberOfPages);

    for (NSUInteger N = theStartIndex; N != theEndIndex; ++N)
        {
        buffer[N - theStartIndex] = [self pageForPageNumber:N];
        }

    state->state = theEndIndex;
    state->itemsPtr = buffer;
    state->mutationsPtr = (__bridge void *)self;

    return(theEndIndex - theStartIndex);
	}

#pragma mark -

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

- (CPDFPage *)pageForPageName:(NSString *)inPageName;
    {
    NSNumber *thePageNumber = [self.pageNumbersByName objectForKey:inPageName];
    if (thePageNumber != NULL)
        {
        return([self pageForPageNumber:thePageNumber.intValue]);
        }

    return(NULL);
    }

#pragma mark -

- (NSDictionary *)pageNumbersByName
    {
    if (_pageNumbersByName == NULL)
        {
        NSMutableDictionary *thePagesByPageInfo = [NSMutableDictionary dictionary];
        size_t theCount = self.numberOfPages;
        for (int N = 0; N != theCount; ++N)
            {
            CPDFPage *thePage = [self pageForPageNumber:N + 1];
            CGPDFDictionaryRef thePageInfo = CGPDFPageGetDictionary(thePage.cg);
            [thePagesByPageInfo setObject:thePage forKey:[NSNumber numberWithInt:(int)thePageInfo]];
            }


        NSMutableDictionary *thePageNumbersForPageNames = [NSMutableDictionary dictionary];

        CGPDFDictionaryRef theCatalog = CGPDFDocumentGetCatalog(self.cg);

        CGPDFObjectRef theObject = NULL;

    //    CGPDFDictionaryGetObject(theCatalog, "Names", &theObject);

        theObject = TXCGPDFDictionaryGetObjectForPath(theCatalog, @"Names.Dests.Kids");

        CGPDFArrayRef theKidsArray = NULL;
        CGPDFObjectGetValue(theObject, kCGPDFObjectTypeArray, &theKidsArray);
        size_t theKidsCount = CGPDFArrayGetCount(theKidsArray);
        for (size_t N = 0; N != theKidsCount; ++N)
            {
            CGPDFDictionaryRef theDictionary = NULL;
            if (CGPDFArrayGetDictionary(theKidsArray, N, &theDictionary) == NO)
                {
                NSLog(@"ERROR #1");
                }
            CGPDFArrayRef theNamesArray = NULL;
            if (CGPDFDictionaryGetArray(theDictionary, "Names", &theNamesArray) == NO)
                {
                NSLog(@"ERROR #2");
                }
            size_t theNamesCount = CGPDFArrayGetCount(theNamesArray);
            for (size_t N = 0; N != theNamesCount; N += 2)
                {
                NSString *thePageName = TXCGPDFArrayGetString(theNamesArray, N);

                CGPDFDictionaryRef theDictionary = NULL;
                CGPDFArrayGetDictionary(theNamesArray, N + 1, &theDictionary);

                CGPDFArrayRef theD = NULL;
                CGPDFDictionaryGetArray(theDictionary, "D", &theD);

                CGPDFDictionaryRef thePageDictionary = NULL;
                CGPDFArrayGetDictionary(theD, 0, &thePageDictionary);



                CPDFPage *thePage = [thePagesByPageInfo objectForKey:[NSNumber numberWithInt:(int)thePageDictionary]];

                [thePageNumbersForPageNames setObject:[NSNumber numberWithInt:thePage.pageNumber] forKey:thePageName];
                }
            }

        _pageNumbersByName = [thePageNumbersForPageNames copy];
        }
    return(_pageNumbersByName);
    }

#pragma mark -

- (void)startGeneratingThumbnails
    {
    const size_t theNumberOfPages = CGPDFDocumentGetNumberOfPages(self.cg);

    // TODO - what if there are multiple queues.
    self.queue = dispatch_queue_create("com.toxicsoftware.pdf-thumbnail-queue", NULL);

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

