//
//  PDFReaderAppDelegate.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/19/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "PDFReaderAppDelegate.h"

@implementation PDFReaderAppDelegate

@synthesize window = _window;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
    {
    [self.window makeKeyAndVisible];

    return YES;
    }

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
    {
    if ([url isFileURL])
        {
        NSString *theDocumentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        
        NSURL *theDestinationURL = [[NSURL fileURLWithPath:theDocumentsPath] URLByAppendingPathComponent:[url lastPathComponent]];
        
        NSError *theError = NULL;
        BOOL theResult = [[NSFileManager defaultManager] moveItemAtURL:url toURL:theDestinationURL error:&theError];
        if (theResult == YES)
            {
            NSMutableDictionary *theUserInfo = [NSMutableDictionary dictionary];
            if (theDestinationURL != NULL)
                {
                [theUserInfo setObject:theDestinationURL forKey:@"URL"];
                }
            if (sourceApplication != NULL)
                {
                [theUserInfo setObject:sourceApplication forKey:@"sourceApplication"];
                }
            if (annotation != NULL)
                {
                [theUserInfo setObject:annotation forKey:@"annotation"];
                }
            [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationDidOpenURL" object:application userInfo:theUserInfo];
            }
        
        return(theResult);
        }
    return(NO);
    }

@end
