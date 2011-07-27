//
//  CPDFDocument_Private.m
//  PDFReader
//
//  Created by Jonathan Wight on 06/01/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CPDFDocument_Private.h"

#import <objc/runtime.h>

#import "CPersistentCache.h"

@implementation CPDFDocument (CPDFDocument_Private)

- (CPersistentCache *)cache
    {
    void *theCacheKey = "cache";
    CPersistentCache *theCache = objc_getAssociatedObject(self, theCacheKey);
    if (theCache == NULL)
        {
        NSString *theCacheName = [[self.URL lastPathComponent] stringByDeletingPathExtension];
        theCache = [[[CPersistentCache alloc] initWithName:theCacheName] autorelease];
        objc_setAssociatedObject(self, theCacheKey, theCache, OBJC_ASSOCIATION_RETAIN);
        }
    return(theCache);
    }

@end
