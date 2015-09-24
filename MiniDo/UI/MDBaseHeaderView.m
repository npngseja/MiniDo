//
//  MDBaseHeaderView.m
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDBaseHeaderView.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"
#import "MDAppControl.h"

@implementation MDBaseHeaderView

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.userInteractionEnabled = YES;
        [self __configureView];
    }
    
    return self;
}

-(void)__configureView
{
    // initial layout is the state when ToDo list is visible
    self.todoHeader = [[UILabel alloc] initWithFrame:CGRectMake(px2p(221), 0, px2p(800), px2p(250))];
    self.todoHeader.textAlignment = NSTextAlignmentCenter;
    NSMutableAttributedString *s = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"You can do it!", nil) attributes:@{NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_BOLD size:hdfs2fs(170)], NSForegroundColorAttributeName: DEFAULT_TEXT_COLOR}];
    [s addAttributes:@{NSForegroundColorAttributeName: DEFAULT_KEY_COLOR} range:[s.string rangeOfString:NSLocalizedString(@"can", nil)]];
    self.todoHeader.attributedText = s;
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedToDoHeader:)];
    [self.todoHeader addGestureRecognizer:gr];
    self.todoHeader.userInteractionEnabled = YES;
    [self addSubview:self.todoHeader];
    
    self.doneHeader = [[UILabel alloc] initWithFrame:CGRectMake(px2p(1010), 0, px2p(500), px2p(250))];
    self.doneHeader.textAlignment = NSTextAlignmentCenter;
    s = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"Done", nil) attributes:@{NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_BOLD size:hdfs2fs(170)], NSForegroundColorAttributeName: DEFAULT_TEXT_COLOR}];
    self.doneHeader.attributedText = s;
    self.doneHeader.alpha = 0.3;
    gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedDoneHeader:)];
    [self.doneHeader addGestureRecognizer:gr];
    self.doneHeader.userInteractionEnabled = YES;
    [self addSubview:self.doneHeader];

}

#pragma mark - Action -
-(void)tappedToDoHeader:(UITapGestureRecognizer*)gr
{
    [[MDAppControl sharedInstance] setActiveListType:MDActiveListTypeToDo animated:YES completionBlock:^{
        
    }];
}

-(void)tappedDoneHeader:(UITapGestureRecognizer*)gr
{
    [[MDAppControl sharedInstance] setActiveListType:MDActiveListTypeDone animated:YES completionBlock:^{
        
    }];
}

#pragma mark - Layout -
-(void)layoutWithTransitionProgress:(CGFloat)progress
{
    
    // transition of todo header
    CGFloat toDoHeaderCenterXWithMinProgress = CGRectGetWidth(self.bounds)/2;
    CGFloat toDoHeaderCenterXWithMaxProgress = -px2p(140);
    CGFloat toDoHeaderAlphaWithMinProgress = 1.0;
    CGFloat toDoHeaderAlphaWithMaxProgress = 0.3;
    
    CGFloat toDoHeaderNewCenterX = toDoHeaderCenterXWithMinProgress + (toDoHeaderCenterXWithMaxProgress-toDoHeaderCenterXWithMinProgress)*progress;
    CGFloat toDoHeaderNewAlpha = toDoHeaderAlphaWithMinProgress + (toDoHeaderAlphaWithMaxProgress-toDoHeaderAlphaWithMinProgress)*progress;
    
    self.todoHeader.center = CGPointMake(toDoHeaderNewCenterX, self.todoHeader.center.y);
    self.todoHeader.alpha = toDoHeaderNewAlpha;
    
    
    // transition of done header
    CGFloat doneHeaderCenterXWithMinProgress = px2p(1260);
    CGFloat doneHeaderCenterXWithMaxProgress = CGRectGetWidth(self.bounds)/2;
    CGFloat doneHeaderAlphaWithMinProgress = 0.3;
    CGFloat doneHeaderAlphaWithMaxProgress = 1.0;
    
    CGFloat doneHeaderNewCenterX = doneHeaderCenterXWithMinProgress + (doneHeaderCenterXWithMaxProgress-doneHeaderCenterXWithMinProgress)*progress;
    CGFloat doneHeaderNewAlpha = doneHeaderAlphaWithMinProgress + (doneHeaderAlphaWithMaxProgress-doneHeaderAlphaWithMinProgress)*progress;
    
    self.doneHeader.center = CGPointMake(doneHeaderNewCenterX, self.doneHeader.center.y);
    self.doneHeader.alpha = doneHeaderNewAlpha;
    
}
@end
