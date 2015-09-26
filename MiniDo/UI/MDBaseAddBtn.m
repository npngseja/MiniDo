//
//  MDBaseAddBtn.m
//  MiniDo
//
//  Created by npngseja on 26/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDBaseAddBtn.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"

@implementation MDBaseAddBtn
{
    CAShapeLayer *__transformingBar;  // |
    CAShapeLayer *__fixedBar; // -
}

-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self __configureView];
    }
    
    return self;
}

-(void)__configureView
{
    __transformingBar = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, px2p(50))];
    [path addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2)];
    [path addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)-px2p(50))];
    __transformingBar.path = path.CGPath;
    __transformingBar.lineCap = kCALineCapRound;
    __transformingBar.lineWidth = 5.0;
    __transformingBar.fillColor = [UIColor clearColor].CGColor;
    __transformingBar.strokeColor = DEFAULT_KEY_COLOR.CGColor;
    [self.layer addSublayer:__transformingBar];
    
    __fixedBar = [CAShapeLayer layer];
    path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(px2p(50), CGRectGetHeight(self.bounds)/2)];
    [path addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)-px2p(50), CGRectGetHeight(self.bounds)/2)];
    __fixedBar.path = path.CGPath;
    __fixedBar.lineCap = kCALineCapRound;
    __fixedBar.lineWidth = 5.0;
    __fixedBar.fillColor = [UIColor clearColor].CGColor;
    __fixedBar.strokeColor = DEFAULT_KEY_COLOR.CGColor;
    [self.layer addSublayer:__fixedBar];
    
}

-(void)makePlus
{
    //Animate path
    
    UIBezierPath *spath = [UIBezierPath bezierPath];
    [spath moveToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, px2p(50))];
    [spath addLineToPoint:CGPointMake(px2p(50), CGRectGetHeight(self.bounds)/2)];
    [spath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)-px2p(50))];
    
    UIBezierPath *tpath = [UIBezierPath bezierPath];
    [tpath moveToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, px2p(50))];
    [tpath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2)];
    [tpath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)-px2p(50))];
    
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.duration = 0.2;
    pathAnimation.fromValue = spath;
    pathAnimation.toValue = tpath;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    __transformingBar.path = tpath.CGPath;
    [__transformingBar addAnimation:pathAnimation forKey:@"path"];
    
}

-(void)makeArrow
{
    //Animate path
    UIBezierPath *spath = [UIBezierPath bezierPath];
    [spath moveToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, px2p(50))];
    [spath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)/2)];
    [spath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)-px2p(50))];
    
    UIBezierPath *tpath = [UIBezierPath bezierPath];
    [tpath moveToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, px2p(50))];
    [tpath addLineToPoint:CGPointMake(px2p(50), CGRectGetHeight(self.bounds)/2)];
    [tpath addLineToPoint:CGPointMake(CGRectGetWidth(self.bounds)/2, CGRectGetHeight(self.bounds)-px2p(50))];
    
    CABasicAnimation *pathAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    pathAnimation.duration = 0.2;
    pathAnimation.fromValue = spath;
    pathAnimation.toValue = tpath;
    pathAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    __transformingBar.path = tpath.CGPath;
    [__transformingBar addAnimation:pathAnimation forKey:@"path"];
}

@end
