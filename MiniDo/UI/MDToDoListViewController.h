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
#import "MDToDoItemView.h"

@interface MDToDoListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonnull, nonatomic, strong) UITableView *tableView;
@property MDActiveListType listType;
@property (nonnull, nonatomic, strong) UIRefreshControl *refreshControl;

/**
 update list view with current todos. this will invoke -(void)reloadData.
 */
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

/**
 search and return todo item view with todo object. if nothing is found, then return nil
 */
-(nullable MDToDoItemView*)todoItemViewForToDoObject:(nonnull MDToDoObject*)todo;

/**
 put back destination of item view on table view. the coordination is in table view coordinate space. it should be converted to be used on other views.
 @return CGPoint wrapped with NSValue. if error occured, it will be nil
 */
-(nullable NSValue*)putBackDestinationCenterOfTodoItemViewOnTableView:(nonnull MDToDoItemView*)itemView;

/**
 put back the item view into its parent cell. the item view should be on place where its parent cell has.
 */
-(void)putBackItemViewIntoParentCell:(nonnull MDToDoItemView*)itemView;

/**
 this method will make the parent cell's todoItemView property nil.
 */
-(void)makeItemViewFreeFromParentCell:(nonnull MDToDoItemView*)itemView;



@end
