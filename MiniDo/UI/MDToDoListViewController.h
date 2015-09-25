//
//  MDToDoListViewController.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDToDoObject.h"
#import "MDMiniDoConstants.h"

@interface MDToDoListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonnull, nonatomic, strong) UITableView *tableView;
@property MDActiveListType listType;

-(void)updateListViewWithCurrentTodo;

/**
 insert a new ToDo Cell
 */
-(void)insertNewToDoCellWithToDoObject:(MDToDoObject * _Nonnull)todo
                              animated:(BOOL)animated;

/**
 remove todo cell
 */
-(void)removeToDoCellWithToDoObject:(MDToDoObject * _Nonnull)todo
                           animated:(BOOL)animated
                    completionBlock:(nullable void (^)())completionBlock;


@end
