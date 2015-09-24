//
//  MDToDoListViewController.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDToDoObject.h"

@interface MDToDoListViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonnull, nonatomic, strong) UITableView *tableView;

/**
 insert a new ToDo Cell
 */
-(void)insertNewToDoCellAnimated:(BOOL)animated;

@end
