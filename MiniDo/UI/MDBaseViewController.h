//
//  MDBaseViewController.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDViewController.h"
#import "MDPopButton.h"
#import "MDBaseHeaderView.h"
#import "MDToDoListViewController.h"

@interface MDBaseViewController : MDViewController <UIScrollViewDelegate>

/**
 contains ToDo and Done lists.
 */
@property (nonatomic, strong, nonnull) UIScrollView *scroller;

/**
 contains list header such as 'You can do it!' and 'Done'
 */
@property (nonatomic, strong, nonnull) MDBaseHeaderView *headerView;

/**
 add a ToDo
 */
@property (nonatomic, strong, nonnull) MDPopButton *addBtn;

/**
 ToDo list view controller
 */
@property (nonatomic, strong, nonnull) MDToDoListViewController *todoListViewController;

/**
 Done list view controller
 */
@property (nonatomic, strong, nonnull) MDToDoListViewController *doneListViewController;
@end
