//
//  CContentScrollView.m
//  PDFReader
//
//  Created by Jonathan Wight on 05/31/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import "CContentScrollView.h"

static void *kKVOContext = NULL;

@interface CContentScrollView ()
- (void)updateContentSizeForFrame:(CGRect)inFrame;
@end

#pragma mark -

@implementation CContentScrollView

@synthesize contentView = contentView; // Note - UIScrollView has an ivar called "_contentView".

- (void)dealloc
    {
    [self removeObserver:self forKeyPath:@"contentView.frame" context:&kKVOContext];
    }

- (void)setFrame:(CGRect)frame
    {
    [super setFrame:frame];
    //
    if (self.contentView)
        {
        CGRect theFrame = self.contentView.frame;

        [self updateContentSizeForFrame:theFrame];
        }
    }

- (void)setContentView:(UIView *)inContentView
    {
    if (contentView != inContentView)
        {
        contentView = inContentView;
        
        [self addObserver:self forKeyPath:@"contentView.frame" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:&kKVOContext];
        }
    }

#pragma mark -

- (void)updateContentSizeForFrame:(CGRect)inFrame
    {
    self.contentSize = inFrame.size;
    
    if (self.contentSize.width < self.bounds.size.width)
        {
        const CGFloat D = self.bounds.size.width - self.contentSize.width;
        self.contentInset = (UIEdgeInsets){ .left = D * 0.5, .right = D * 0.5 };
        }
    }

#pragma mark -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
    {
    if (context == &kKVOContext)
        {
        CGRect theFrame = [[change objectForKey:NSKeyValueChangeNewKey] CGRectValue];
        
        [self updateContentSizeForFrame:theFrame];
        }
    }

@end
