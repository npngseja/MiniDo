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

-(void)updateListViewWithCurrentTodo
{
   [[MDUserManager sharedInstance] fetchTodosForListType:self.listType completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
       __todos = [results mutableCopy];
       
       [self.tableView reloadData];
   }];
}

#pragma mark - ToDo Cell Management -
-(void)insertNewToDoCellWithToDoObject:(MDToDoObject * _Nonnull)todo
                              animated:(BOOL)animated;
{
    // we insert new todo on head.
    [__todos insertObject:todo atIndex:0];
    
    [CATransaction begin];
    [self.tableView beginUpdates];
    [CATransaction setCompletionBlock:^{
        MDToDoListTableViewCell *firstCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
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
    
    [CATransaction begin];
    [self.tableView beginUpdates];
    [CATransaction setCompletionBlock:^{
        
    }];
    [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForItem:index inSection:0]] withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
    [__todos removeObject:todo];
    [self.tableView endUpdates];
    [CATransaction commit];
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
        
        cell.showsReorderControl = YES;
        
    }
    
    // update cell's content with data
    MDToDoObject *todo = __todos[indexPath.row];
    [cell updateToDoObject:todo];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return TODO_CELL_HEIGHT;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    
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
