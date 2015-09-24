//
//  MDMiniDoConstants.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDMiniDoUtils.h"

FOUNDATION_EXPORT CGFloat px2p(CGFloat px) {
    return ((((px)/1242.0)*[UIScreen mainScreen].bounds.size.width));
}

FOUNDATION_EXPORT CGFloat hdfs2fs(CGFloat fs) {
    return round(fs/((1242.0/([UIScreen mainScreen].bounds.size.width > 375 ? [UIScreen mainScreen].bounds.size.width : [UIScreen mainScreen].bounds.size.width+20))));
}