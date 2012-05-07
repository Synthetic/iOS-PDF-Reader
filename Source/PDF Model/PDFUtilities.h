//
//  PDFUtilities.h
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

extern id TXConvertPDFObject(CGPDFObjectRef inObject);
extern void TXCGPDFDictionaryApplyBlock(CGPDFDictionaryRef inDictionary, void (^inBlock)(const char *key, CGPDFObjectRef value));
extern NSString *TXCGPDFDictionaryGetString(CGPDFDictionaryRef inDictionary, const char *inKey);
extern NSString *TXCGPDFArrayGetString(CGPDFArrayRef inArray, size_t N);

extern CGPDFObjectRef TXCGPDFDictionaryGetObjectForPath(CGPDFDictionaryRef inDictionary, NSString *inPath);

extern NSString *TXCGPDFObjectAsString(CGPDFObjectRef inObject);