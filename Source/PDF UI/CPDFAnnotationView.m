//
//  CPDFAnnotationView.m
//  PDFReader
//
//  Created by Jonathan Wight on 5/3/12.
//  Copyright (c) 2012 toxicsoftware.com. All rights reserved.
//

#import "CPDFAnnotationView.h"

#import "CPDFAnnotation.h"
#import "PDFUtilities.h"
#import "CPDFStream.h"

#import <MediaPlayer/MediaPlayer.h>

@interface CPDFAnnotationView ()
@property (readwrite, nonatomic, strong) MPMoviePlayerController *moviePlayer;
@end

#pragma mark -

@implementation CPDFAnnotationView

@synthesize annotation = _annotation;
@synthesize moviePlayer = _moviePlayer;

- (id)initWithAnnotation:(CPDFAnnotation *)inAnnotation;
    {
    if ((self = [super initWithFrame:inAnnotation.frame]) != NULL)
        {
        _annotation = inAnnotation;
        }
    return(self);
    }

- (void)layoutSubviews
    {
    [super layoutSubviews];
    //
    if (self.moviePlayer == NULL)
        {
        NSURL *theURL = NULL;
        theURL = self.annotation.URL;

        if (theURL == NULL)
            {
            theURL = [self.annotation.stream fileURLWithPathExtension:@"mov"];
            }

        if (theURL)
            {
            self.moviePlayer = [[MPMoviePlayerController alloc] initWithContentURL:theURL];
            self.moviePlayer.view.frame = self.bounds;
            self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            [self.moviePlayer prepareToPlay];
            [self addSubview:self.moviePlayer.view];


            double delayInSeconds = 2.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//                [self.moviePlayer play];
                });
            }
        }
    }


@end
