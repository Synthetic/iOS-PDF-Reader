//
//  CPagingView.m
//  PDFReader
//
//  Created by Jonathan Wight on 02/20/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//0.1

#import "CPageControl.h"

@interface CPageControl ()
@property (readwrite, nonatomic, assign) BOOL viewsHidden;
@end

@implementation CPageControl

@synthesize leftView = _leftView, rightView = _rightView, topView = _topView, bottomView = _bottomView;
@synthesize target = _target, nextAction = _nextAction, previousAction = _previousAction;

@synthesize viewsHidden = _viewsHidden;

- (id)initWithCoder:(NSCoder *)inDecoder
    {
    if ((self = [super initWithCoder:inDecoder]) != NULL)
        {
        }
    return(self);
    }

- (void)awakeFromNib
    {
    CGFloat W = 128;
    CGFloat H = 128;
    CGFloat theAlpha = 0.05;

    const CGSize theBoundsSize = self.bounds.size;

    self.leftView = [[UIView alloc] initWithFrame:(CGRect){ .origin = { 0, H }, .size = { W, theBoundsSize.height - H * 2 } }];
    self.leftView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleRightMargin;
    self.leftView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:theAlpha];
    [self addSubview:self.leftView];

    self.topView = [[UIView alloc] initWithFrame:(CGRect){ .origin = { 0, 0 }, .size = { theBoundsSize.width, H } }];
    self.topView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    self.topView.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:theAlpha];
    [self addSubview:self.topView];

    self.rightView = [[UIView alloc] initWithFrame:(CGRect){ .origin = { theBoundsSize.width - W, H }, .size = { W, theBoundsSize.height - H * 2 } }];
    self.rightView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.rightView.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:theAlpha];
    [self addSubview:self.rightView];

    self.bottomView = [[UIView alloc] initWithFrame:(CGRect){ .origin = { 0, theBoundsSize.height - H }, .size = { theBoundsSize.width, H } }];
    self.bottomView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    self.bottomView.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:theAlpha];
    [self addSubview:self.bottomView];

    [self.leftView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [self.rightView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [self.topView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];
    [self.bottomView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap:)]];

    if (self.viewsHidden == NO)
        {
        self.viewsHidden = YES;
        [UIView animateWithDuration:2.0 delay:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^(void) {
            self.leftView.backgroundColor = [self.leftView.backgroundColor colorWithAlphaComponent:0.0];
            self.rightView.backgroundColor = [self.leftView.backgroundColor colorWithAlphaComponent:0.0];
            self.topView.backgroundColor = [self.leftView.backgroundColor colorWithAlphaComponent:0.0];
            self.bottomView.backgroundColor = [self.leftView.backgroundColor colorWithAlphaComponent:0.0];
            } completion:NULL];
        }
    }

//- (void)drawRect:(CGRect)rect
//    {
//    }

- (void)tap:(UITapGestureRecognizer *)inSender
    {
    if (inSender.view == self.rightView || inSender.view == self.bottomView)
        {
        [self.target performSelector:self.nextAction withObject:self];
        }
    else if (inSender.view == self.leftView || inSender.view == self.topView)
        {
        [self.target performSelector:self.previousAction withObject:self];
        }
    }

@end
