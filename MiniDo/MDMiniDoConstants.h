//
//  MDMiniDoConstants.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#ifndef MDMiniDoConstants_h
#define MDMiniDoConstants_h

// we allow maximum 200 todos for a user!
#define MAX_TODO_COUNT 200

#define DEFAULT_COLOR_WHITE [UIColor whiteColor]
#define DEFAULT_COLOR_BLACK [UIColor blackColor]

#define DEFAULT_KEY_COLOR [UIColor colorWithRed:255/255.0 green:47/255.0 blue:146/255.0 alpha:1.0]
#define DEFAULT_BG_COLOR [UIColor whiteColor]
#define DEFAULT_TEXT_COLOR DEFAULT_COLOR_WHITE

#define DEFAULT_FONT_REGULAR @"Lato-Light"
#define DEFAULT_FONT_BOLD @"Lato-Light"
#define DEFAULT_FONT_LIGHT @"Lato-Light"

#define TODO_CELL_HEIGHT px2p(300)

typedef NS_ENUM(NSInteger, MDActiveListType) {
    MDActiveListTypeToDo,
    MDActiveListTypeDone
};

#endif /* MDMiniDoConstants_h */
