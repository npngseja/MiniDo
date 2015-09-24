//
//  MDBaseHeaderView.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MDBaseHeaderView : UIView

@property (nonatomic, strong, nonnull) UILabel *todoHeader;
@property (nonatomic, strong, nonnull) UILabel *doneHeader;

/**
 @param progress
        The value is between 0 and 1. If it is 0, then todo header is in the cetner (active). If it 1, then done header is in the center. The values inbetween indicates transition progress
 */
-(void)layoutWithTransitionProgress:(CGFloat)progress;
@end
