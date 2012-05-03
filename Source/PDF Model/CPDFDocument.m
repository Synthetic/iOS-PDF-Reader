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

//    CGPDFDictionaryApplyBlock(CGPDFDocumentGetCatalog(_cg), ^(const char *key, CGPDFObjectRef value) {
//        NSLog(@"### %s", key);
//        NSLog(@"%@", ConvertPDFObject(value));
//        });



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

