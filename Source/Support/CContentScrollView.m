//
//  CContentScrollView.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 05/31/11.
//  Copyright 2012 Jonathan Wight. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification, are
//  permitted provided that the following conditions are met:
//
//     1. Redistributions of source code must retain the above copyright notice, this list of
//        conditions and the following disclaimer.
//
//     2. Redistributions in binary form must reproduce the above copyright notice, this list
//        of conditions and the following disclaimer in the documentation and/or other materials
//        provided with the distribution.
//
//  THIS SOFTWARE IS PROVIDED BY JONATHAN WIGHT ``AS IS'' AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//  FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JONATHAN WIGHT OR
//  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//  ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  The views and conclusions contained in the software and documentation are those of the
//  authors and should not be interpreted as representing official policies, either expressed
//  or implied, of Jonathan Wight.

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
