//
//  PDFUtilities.h
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

extern id ConvertPDFObject(CGPDFObjectRef inObject);
extern void CGPDFDictionaryApplyBlock(CGPDFDictionaryRef inDictionary, void (^inBlock)(const char *key, CGPDFObjectRef value));
extern CGPDFObjectRef MyCGPDFDictionaryGetObjectForPath(CGPDFDictionaryRef inDictionary, NSString *inPath);
extern NSString *MyCGPDFDictionaryGetString(CGPDFDictionaryRef inDictionary, const char *inKey);
extern NSString *MyCGPDFArrayGetString(CGPDFArrayRef inArray, size_t N);

extern CGPDFObjectRef MyCGPDFDictionaryGetObjectForPath_2(CGPDFDictionaryRef inDictionary, NSString *inPath);

extern NSString *MyCGPDFObjectAsString(CGPDFObjectRef inObject);