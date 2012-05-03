//
//  CPDFAnnotation.h
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CPDFAnnotation : NSObject

@property (readonly, nonatomic, strong) NSString *subtype;
@property (readonly, nonatomic, assign) CGRect frame;
@property (readonly, nonatomic, strong) NSDictionary *info;

- (id)initWithDictionary:(CGPDFDictionaryRef)inDictionary;

@end
