//
//  MDBaseViewController.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDViewController.h"
#import "MDBaseAddBtn.h"
#import "MDBaseHeaderView.h"
#import "MDToDoListViewController.h"
#import "MDToDoObject.h"

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
@property (nonatomic, strong, nonnull) MDBaseAddBtn *addBtn;

/**
 ToDo list view controller
 */
@property (nonatomic, strong, nonnull) MDToDoListViewController *todoListViewController;

/**
 Done list view controller
 */
@property (nonatomic, strong, nonnull) MDToDoListViewController *doneListViewController;

/**
 make a todo item view focuses
 */
-(void)focusOnToDo:(nonnull MDToDoObject*)todo completionBlock:(nullable void (^)(BOOL succeed))completionBlock;

/**
 dismiss todo focus
 */
-(void)dismissToDoFocus:(nonnull MDToDoObject*)todo completionBlock:(nullable void (^)(BOOL succeed))completionBlock;

/**
 force to dismiss todo focus. this is useful for deleted todo.
 */
-(void)forceToDismissFocusModeWithCompletionBlock:(nullable void (^)())completionBlock;

/**
 move todo item from source list to target list. The item will be inserted on top of the target list
 */
- (void)moveToDo:(nonnull MDToDoObject*)todo sourceListType:(MDActiveListType)sourceListType targetListType:(MDActiveListType)targetListType completionBlock:(nullable void (^)())completionBlock;

@end
