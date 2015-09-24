//
//  MDToDoListTableViewCell.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDToDoObject.h"
#import "MDToDoItemView.h"
@interface MDToDoListTableViewCell : UITableViewCell

/**
 This view contains actual UI elements. Cell serves just as a container.
 */
@property (nullable, nonatomic, strong) MDToDoItemView *todoItemView;

/**
 Set todo data object. We set todo data object in 'todoItemView'. This will automatically update visible content of the cell
 */
-(void)updateToDoObject:(nonnull MDToDoObject*)todo;

@end
