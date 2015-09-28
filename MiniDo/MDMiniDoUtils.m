//
//  MDMiniDoConstants.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDMiniDoUtils.h"

FOUNDATION_EXPORT CGFloat px2p(CGFloat px) {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return ((((px)/1242.0)*[UIScreen mainScreen].bounds.size.width));
    } else {
        // pad.... iPad's coordinate space is based on old iPhones which had 320 points width.
        return ((px)/1242.0)*320;
    }
}

FOUNDATION_EXPORT CGFloat hdfs2fs(CGFloat fs) {
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return ((((fs)/1242.0)*[UIScreen mainScreen].bounds.size.width));
    } else {
        // pad
        return ((fs)/1242.0)*320;
    }
}

FOUNDATION_EXPORT CGFloat deg2rad(CGFloat deg) {
    return  (deg*M_PI/180.0);
}

FOUNDATION_EXPORT CGFloat todo_itemView_width()
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        return CGRectGetWidth([UIScreen mainScreen].bounds);
    } else {
        return 407;
    }
}