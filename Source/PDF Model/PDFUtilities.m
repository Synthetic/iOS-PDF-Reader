//
//  PDFUtilities.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "PDFUtilities.h"

#import "CPDFStream.h"
#import "CPDFObjectReference.h"

static id ConvertPDFObject_(CGPDFObjectRef inObject, NSMutableSet *convertedPointers);
static void MyCGPDFDictionaryApplierFunction(const char *key, CGPDFObjectRef value, void *info);

id ConvertPDFObject(CGPDFObjectRef inObject)
    {
    return(ConvertPDFObject_(inObject, [NSMutableSet set]));
    }

static id ConvertPDFObject_(CGPDFObjectRef inObject, NSMutableSet *convertedPointers)
    {
    const CGPDFObjectType theType = CGPDFObjectGetType(inObject);

    if (theType == kCGPDFObjectTypeArray || theType == kCGPDFObjectTypeDictionary)
        {
        NSNumber *theKey = [NSNumber numberWithInt:(int)inObject];
        if ([convertedPointers containsObject:theKey])
            {
            return([[CPDFObjectReference alloc] init]);
            }
        else
            {
            [convertedPointers addObject:theKey];
            }
        }

    id theResult = NULL;
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
                id theObject = ConvertPDFObject_(thePDFObject, convertedPointers);
                [theArray addObject:theObject];
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
                id theObject = NULL;
                theObject = ConvertPDFObject_(value, convertedPointers);
                [theDictionary setObject:theObject forKey:theKey];
                });
            theResult = theDictionary;
            }
            break;
        case kCGPDFObjectTypeStream:
            {
            CGPDFStreamRef theValue = NULL;
            CGPDFObjectGetValue(inObject, theType, &theValue);

            theResult = [[CPDFStream alloc] initWithStream:theValue];
            }
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

CGPDFObjectRef MyCGPDFDictionaryGetObjectForPath(CGPDFDictionaryRef inDictionary, NSString *inPath)
    {
    NSArray *theComponents = [inPath componentsSeparatedByString:@"."];

    CGPDFObjectRef theObject = NULL;

    void *theContainer = inDictionary;
    for (NSString *theComponent in theComponents)
        {
        if ([theComponent characterAtIndex:0] == '#')
            {
            NSUInteger theIndex = [[theComponent substringFromIndex:1] integerValue];
            CGPDFArrayGetObject(theContainer, theIndex, &theObject);
            }
        else
            {
            CGPDFDictionaryGetObject(theContainer, [theComponent UTF8String], &theObject);
            }

        CGPDFObjectType theType = CGPDFObjectGetType(theObject);
        if (theType == kCGPDFObjectTypeDictionary || theType == kCGPDFObjectTypeArray)
            {
            CGPDFObjectGetValue(theObject, theType, &theContainer);
            }
        else
            {
            break;
            }
        }

    return(theObject);
    }

NSString *MyCGPDFDictionaryGetString(CGPDFDictionaryRef inDictionary, const char *inKey)
    {
    CGPDFObjectRef theObject = NULL;
    CGPDFDictionaryGetObject(inDictionary, inKey, &theObject);
    return(MyCGPDFObjectAsString(theObject));
    }

NSString *MyCGPDFArrayGetString(CGPDFArrayRef inArray, size_t N)
    {
    CGPDFObjectRef theObject = NULL;
    CGPDFArrayGetObject(inArray, N, &theObject);
    return(MyCGPDFObjectAsString(theObject));
    }

NSString *MyCGPDFObjectAsString(CGPDFObjectRef inObject)
    {
    CGPDFObjectType theType = CGPDFObjectGetType(inObject);
    if (theType == kCGPDFObjectTypeString)
        {
        CGPDFStringRef thePDFString = NULL;
        CGPDFObjectGetValue(inObject, kCGPDFObjectTypeString, &thePDFString);
        return((__bridge_transfer NSString *)CGPDFStringCopyTextString(thePDFString));
        }
    else if (theType == kCGPDFObjectTypeName)
        {
        const char *theValue;
        CGPDFObjectGetValue(inObject, kCGPDFObjectTypeName, &theValue);
        return([NSString stringWithUTF8String:theValue]);
        }
    else
        {
        return(NULL);
        }
    }