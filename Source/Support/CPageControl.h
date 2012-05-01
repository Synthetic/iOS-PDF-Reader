//
//  CPagingView.h
//  PDFReader
//
//  Created by Jonathan Wight on 02/20/11.
//  Copyright 2011 toxicsoftware.com. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface CPageControl : UIControl

@property (readwrite, nonatomic, strong) IBOutlet UIView *leftView;
@property (readwrite, nonatomic, strong) IBOutlet UIView *rightView;
@property (readwrite, nonatomic, strong) IBOutlet UIView *topView;
@property (readwrite, nonatomic, strong) IBOutlet UIView *bottomView;

@property (readwrite, nonatomic, weak) id target;
@property (readwrite, nonatomic, assign) SEL nextAction;
@property (readwrite, nonatomic, assign) SEL previousAction;

@end
