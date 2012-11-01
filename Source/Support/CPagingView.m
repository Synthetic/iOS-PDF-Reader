//
//  CMyScrollView.m
//  iOS-PDF-Reader
//
//  Created by Jonathan Wight on 02/19/11.
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

#import "CPagingView.h"

@interface CPagingView () <UIScrollViewDelegate>
@property (readwrite, nonatomic, assign) NSUInteger currentPageIndex;

@property (readwrite, nonatomic, strong) UIView *previousView;
@property (readwrite, nonatomic, strong) UIView *currentView;
@property (readwrite, nonatomic, strong) UIView *nextView;

@property (readwrite, nonatomic, strong) UIScrollView *scrollView;
@property (readwrite, nonatomic, assign) NSUInteger numberOfPages;

- (void)updatePages;

@end

@implementation CPagingView

@synthesize delegate = _delegate;
@synthesize dataSource = _dataSource;
@synthesize currentPageIndex = _currentPageIndex;
@synthesize previousView = _previousView;
@synthesize currentView = _currentView;
@synthesize nextView = _nextView;

@synthesize scrollView = _scrollView;
@synthesize numberOfPages = _numberOfPages;

- (id)initWithCoder:(NSCoder *)inDecoder
	{
	if ((self = [super initWithCoder:inDecoder]) != NULL)
		{
        _scrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _scrollView.delegate = self;
        _scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [self addSubview:_scrollView];
		}
	return(self);
	}

- (void)setFrame:(CGRect)inBounds
    {
    [super setFrame:inBounds];
    
    if (self.dataSource)
        {
        const NSUInteger theNumberOfPages = [self.dataSource numberOfPagesInPagingView:self];        
        CGRect theBounds = self.bounds;
        self.scrollView.contentSize = (CGSize){ theBounds.size.width * theNumberOfPages, theBounds.size.height };
        
        [self updatePages];
        }
    }

- (void)setDataSource:(id<CPagingViewDataSource>)inDataSource
    {
    if (_dataSource != inDataSource)
        {
        _dataSource = inDataSource;
        
        self.numberOfPages = [self.dataSource numberOfPagesInPagingView:self];        
        CGRect theBounds = self.bounds;
        self.scrollView.contentSize = (CGSize){ theBounds.size.width * self.numberOfPages, theBounds.size.height };

        [self updatePages];
        }
    }

- (void)scrollToPageAtIndex:(NSUInteger)inIndex animated:(BOOL)inAnimated;
    {
    if (inIndex < self.numberOfPages)
        {
        const CGSize thePageSize = self.bounds.size;
        CGRect theScrollRect = { .origin = { .x = thePageSize.width * inIndex, .y = 0 }, .size = thePageSize };
        [self.scrollView scrollRectToVisible:theScrollRect animated:inAnimated];

        self.currentPageIndex = inIndex;
        }
    }

- (void)scrollToPreviousPageAnimated:(BOOL)inAnimated;
    {
    [self scrollToPageAtIndex:self.currentPageIndex - 1 animated:inAnimated];
    }

- (void)scrollToNextPageAnimated:(BOOL)inAnimated;
    {
    [self scrollToPageAtIndex:self.currentPageIndex + 1 animated:inAnimated];
    }

#pragma mark -

- (void)updatePages
    {
    const CGSize thePageSize = self.bounds.size;
    
    // TODO -- dont remove views if we can get them from old values of previous, current, next
    
    if (self.currentView.superview == self.scrollView)
        {
        [self.currentView removeFromSuperview];
        self.currentView = NULL;
        }

    if (self.previousView.superview == self.scrollView)
        {
        [self.previousView removeFromSuperview];
        self.previousView = NULL;
        }

    if (self.nextView.superview == self.scrollView)
        {
        [self.nextView removeFromSuperview];
        self.nextView = NULL;
        }

    //    
    self.currentView = [self.dataSource pagingView:self viewForPageAtIndex:self.currentPageIndex];
    self.currentView.frame = (CGRect){ .origin = { .x = thePageSize.width * self.currentPageIndex, .y = 0 }, .size = thePageSize };
    self.currentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.scrollView addSubview:self.currentView];

    if (self.currentPageIndex >= 1)
        {
        self.previousView = [self.dataSource pagingView:self viewForPageAtIndex:self.currentPageIndex - 1];
        self.previousView.frame = (CGRect){ .origin = { .x = thePageSize.width * (self.currentPageIndex - 1), .y = 0 }, .size = thePageSize };
        self.previousView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:self.previousView];
        }

    if (self.currentPageIndex < self.numberOfPages)
        {
        self.nextView = [self.dataSource pagingView:self viewForPageAtIndex:self.currentPageIndex + 1];
        self.nextView.frame = (CGRect){ .origin = { .x = thePageSize.width * (self.currentPageIndex + 1), .y = 0 }, .size = thePageSize };
        self.nextView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.scrollView addSubview:self.nextView];
        }
    }

#pragma mark -

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)inScrollView   
    {
    [self performSelector:@selector(updatePages) withObject:NULL afterDelay:0.0];
    }

@end
