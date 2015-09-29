//
//  MDPopButton.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDPopButton.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"

@implementation MDPopButton
{
    
    BOOL __isAnimating;
    BOOL __wasTap;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
        [self addTarget:self action:@selector(touchDown:) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(touchDone:) forControlEvents:UIControlEventTouchCancel];
        [self addTarget:self action:@selector(touchDone:) forControlEvents:UIControlEventTouchUpOutside];
        [self addTarget:self action:@selector(touchDone:) forControlEvents:UIControlEventTouchUpInside];
    }
    return self;
}

#pragma mark - Button Effects
-(void)touchDown:(UIButton*)btn
{
    __isAnimating = YES;
    [UIView animateWithDuration:0.2 animations:^{
        self.transform = CGAffineTransformMakeScale(1.05, 1.05);
    } completion:^(BOOL finished) {
        __isAnimating = NO;
        if (__wasTap) {
            [UIView animateWithDuration:0.1 animations:^{
                self.transform = CGAffineTransformMakeScale(1.0, 1.0);
            }];
            
            __wasTap = NO;
        }
    }];
}

-(void)touchDone:(UIButton*)btn
{
    if (__isAnimating) {
        // user made a short tap, which calls this method while button animation.
        // We make button's scale to 1.0 AFTER the popping animation. The flag below is to control that.
        // See -(void)touchDown: method
        __wasTap = YES;
        return;
    }
    
    // button animation is done, and user finished tap. we can make the button's scale to 1.0 safely.
    [UIView animateWithDuration:0.1 animations:^{
        self.transform = CGAffineTransformMakeScale(1.0, 1.0);
    }];

}

@end
