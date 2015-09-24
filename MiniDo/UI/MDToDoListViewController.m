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

@interface MDToDoListViewController ()

@end

@implementation MDToDoListViewController
{
    
    NSMutableArray *_dummy;

}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.editing = YES;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.tableView];
    
    _dummy = [@[] mutableCopy];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - ToDo Cell Management -
-(void)insertNewToDoCellAnimated:(BOOL)animated
{
    [self.tableView beginUpdates];
    //ToDo: update data source here!
    [_dummy addObject:@"CCC"];
    // we push new cell on top!
    [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]]
                          withRowAnimation:animated ? UITableViewRowAnimationTop : UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

#pragma mark - TableView Datasource & Delegate -
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _dummy.count;
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
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return px2p(300);
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
