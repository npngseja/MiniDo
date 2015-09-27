//
//  MDToDoListViewController.m
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDToDoListViewController.h"
#import "MDToDoListTableViewCell.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"
#import "MDUserManager.h"

@interface MDToDoListViewController ()

@end

@implementation MDToDoListViewController
{
    
    NSMutableArray *__todos;
    UILabel *__msgForEmptyList;

}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    __todos = [@[] mutableCopy];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.editing = YES;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)__showMsgForEmptyListIfNecessary
{
    if (__todos.count == 0) {
        if (__msgForEmptyList == nil) {
            __msgForEmptyList = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds)*0.7)];
            __msgForEmptyList.textAlignment = NSTextAlignmentCenter;
            __msgForEmptyList.numberOfLines = 10;
            if (self.listType == MDActiveListTypeToDo) {
                NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"TAP\n+\nTO CREATE A TASK", nil) attributes:@{NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_LIGHT size:hdfs2fs(100)], NSForegroundColorAttributeName: DEFAULT_TEXT_COLOR}];
                [atr addAttributes:@{NSForegroundColorAttributeName: DEFAULT_KEY_COLOR, NSFontAttributeName: [UIFont fontWithName:@"Helvetica" size:hdfs2fs(130)]} range:[atr.string rangeOfString:@"+"]];
                __msgForEmptyList.attributedText = atr;
            } else {
                NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:NSLocalizedString(@"HERE YOU FIND\n\nWHAT YOU'VE DONE", nil) attributes:@{NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_LIGHT size:hdfs2fs(100)], NSForegroundColorAttributeName: DEFAULT_TEXT_COLOR}];
                [atr addAttributes:@{NSForegroundColorAttributeName: DEFAULT_KEY_COLOR, NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_BOLD size:hdfs2fs(100)]} range:[atr.string rangeOfString:@"DONE"]];
                __msgForEmptyList.attributedText = atr;

            }
            [self.view addSubview:__msgForEmptyList];
        }
    }
}

- (void)__removeMsgForEmptyList
{
    if (__msgForEmptyList != nil) {
        [__msgForEmptyList removeFromSuperview];
        __msgForEmptyList = nil;
    }
}

#pragma mark - ToDo List Management -
-(void)updateListViewWithCurrentTodo
{
    [[MDUserManager sharedInstance] fetchTodosForListType:self.listType completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
        if (succeed == YES) {
            [__todos removeAllObjects];
            [__todos addObjectsFromArray:results];
        }
        
        // reload table view
        [self.tableView reloadData];
        
        // show msg if we have no todos.
        [self __showMsgForEmptyListIfNecessary];
        
    }];
}

-(void)insertNewToDoCellWithToDoObject:(MDToDoObject * _Nonnull)todo
                              animated:(BOOL)animated;
{
    // we insert new todo on head.
    [__todos insertObject:todo atIndex:0];
    
    [self __removeMsgForEmptyList];
    
    [CATransaction begin];
    [self.tableView beginUpdates];
    [CATransaction setCompletionBlock:^{
        MDToDoListTableViewCell *firstCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [firstCell startToDoTextEdit];
        
        
    }];
    
    // we push new cell on top.
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:animated ? UITableViewRowAnimationTop : UITableViewRowAnimationNone];
    [self.tableView endUpdates];
    [CATransaction commit];
}

-(void)removeToDoCellWithToDoObject:(MDToDoObject * _Nonnull)todo
                           animated:(BOOL)animated
                    completionBlock:(nullable void (^)())completionBlock
{
    NSInteger index = [__todos indexOfObject:todo];
    NSAssert(index >= 0 && index < __todos.count, @"todo object is not found from list data source!");
    
    // reset todoItemView before remove its parent cell.
    // this is necessary to re-use the cell for other content presentation.
    // when a todo is removed, todoItemView is out of the screen. we need to have it back.
    MDToDoListTableViewCell *parentCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    MDToDoItemView *itemView = parentCell.todoItemView;
    itemView.isFocused = NO;
    itemView.transform = CGAffineTransformIdentity;
    itemView.frame = CGRectMake(0, 0, TODO_CELL_WIDTH, TODO_CELL_HEIGHT);
    itemView.hidden = YES;
    [parentCell.contentView addSubview:itemView];
    
    // begin with cell remove
    [CATransaction begin];
    [self.tableView beginUpdates];
    [CATransaction setCompletionBlock:^{
        [self __showMsgForEmptyListIfNecessary];
        if (completionBlock) {
            completionBlock();
        }
    }];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
    [__todos removeObject:todo];
    [self.tableView endUpdates];
    [CATransaction commit];
}

-(MDToDoItemView*)todoItemViewForToDoObject:(MDToDoObject *)todo
{
    NSInteger index = [__todos indexOfObject:todo];
    if (index < 0 || index >= __todos.count) {
        NSLog(@"[MDToDoListViewController] todo is not found in the data source!: %@", todo.text);
        return nil;
    }
    
    MDToDoListTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    
    return cell.todoItemView;
}

-(nullable NSValue*)putBackDestinationCenterOfTodoItemViewOnTableView:(nonnull MDToDoItemView*)itemView
{
    // find parent cell
    MDToDoObject *todo = itemView.todo;
    NSInteger index = [__todos indexOfObject:todo];
    if (index < 0 || index >= __todos.count) {
        NSLog(@"[MDToDoListViewController] todo is not found in the data source!: %@", todo.text);
        return nil;
    }
    
    // calc destination of the itemview
    MDToDoListTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    CGPoint destinationOnTableView = cell.center;
    
    return [NSValue valueWithCGPoint:destinationOnTableView];
    
}

-(void)putBackItemViewIntoParentCell:(MDToDoItemView *)itemView
{
    // find parent cell
    MDToDoObject *todo = itemView.todo;
    NSInteger index = [__todos indexOfObject:todo];
    if (index < 0 || index >= __todos.count) {
        NSLog(@"[MDToDoListViewController] todo is not found in the data source!: %@", todo.text);
        return;
    }
    
    MDToDoListTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];

    itemView.center = CGPointMake(CGRectGetWidth(itemView.bounds)/2, CGRectGetHeight(itemView.bounds)/2);
    [cell.contentView addSubview:itemView];
    
}

-(void)makeItemViewFreeFromParentCell:(MDToDoItemView *)itemView
{
    // find parent cell
    MDToDoObject *todo = itemView.todo;
    NSInteger index = [__todos indexOfObject:todo];
    if (index < 0 || index >= __todos.count) {
        NSLog(@"[MDToDoListViewController] todo is not found in the data source!: %@", todo.text);
        return;
    }
    
    MDToDoListTableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    cell.todoItemView = nil;
}

#pragma mark - TableView Datasource & Delegate -
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return __todos.count;
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellReuseId = @"MDToDoListTableViewCell";
    MDToDoListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseId];
    
    if (cell == nil) {
        // init cell
        cell = [[MDToDoListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseId];
    }
    
    // update cell's content with data
    MDToDoObject *todo = __todos[indexPath.row];
    [cell updateToDoObject:todo];
    // while remove action, sometimes itemView is hidden. here we should make it visible.
    cell.todoItemView.hidden = NO;
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TODO_CELL_HEIGHT;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.listType == MDActiveListTypeToDo) {
        return YES;
    } else {
        return NO;
    }
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    // change list's data source
    MDToDoObject *object = [__todos objectAtIndex:sourceIndexPath.row];
    [__todos removeObjectAtIndex:sourceIndexPath.row];
    [__todos insertObject:object atIndex:destinationIndexPath.row];
    
    // change priority
    MDToDoObject *currentToDo = object;
    NSInteger indexOfCurrentToDo = [__todos indexOfObject:currentToDo];
    NSInteger indexOfPrevToDo = indexOfCurrentToDo-1;
    NSInteger indexOfNextToDo = indexOfCurrentToDo+1;
    MDToDoObject *prevToDo = (indexOfPrevToDo >= 0 && indexOfPrevToDo < __todos.count) ? __todos[indexOfPrevToDo] : nil;
    MDToDoObject *nextToDo = (indexOfNextToDo >= 0 && indexOfNextToDo < __todos.count) ? __todos[indexOfNextToDo] : nil;
    
    // note that __todos is sorted descending!!!
    [[MDUserManager sharedInstance] changePriorityOfToDo:currentToDo greaterThanToDo:nextToDo lessThanToDo:prevToDo completionBlock:^(BOOL succeed) {
        if (succeed == NO) {
            NSLog(@"[WARNING] change priority of todo in a list is failed!!!!!!!!");
        }
    }];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone;
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}





@end
