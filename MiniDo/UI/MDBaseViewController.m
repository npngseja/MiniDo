//
//  MDBaseViewController.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDBaseViewController.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"
#import "MDAppControl.h"

@interface MDBaseViewController ()
{
    BOOL __isFirstLoad;
}
@end

@implementation MDBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // this is the first load of the viewcontroller
    __isFirstLoad = YES;
    
    // set application background
    self.view.backgroundColor = DEFAULT_BG_COLOR;
    
    // base scroller
    self.scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(0, px2p(410), CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - px2p(410))];
    self.scroller.showsHorizontalScrollIndicator = NO;
    self.scroller.showsVerticalScrollIndicator = NO;
    self.scroller.pagingEnabled = YES;
    self.scroller.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.scroller.delegate = self;
    self.scroller.contentSize = CGSizeMake(CGRectGetWidth(self.scroller.bounds)*2, CGRectGetHeight(self.scroller.bounds));
    [self.view addSubview:self.scroller];
    
    // todo list view controller
    self.todoListViewController = [[MDToDoListViewController alloc] init];
    self.todoListViewController.view.frame = self.scroller.bounds;
    [self.scroller addSubview:self.todoListViewController.view];
    
    // done list view controller
    self.doneListViewController = [[MDToDoListViewController alloc] init];
    self.doneListViewController.view.frame = CGRectMake(CGRectGetWidth(self.scroller.bounds), 0, CGRectGetWidth(self.scroller.bounds), CGRectGetHeight(self.scroller.bounds));
    self.doneListViewController.tableView.backgroundColor = DEFAULT_KEY_COLOR;
    [self.scroller addSubview:self.doneListViewController.view];
    
    // add button
    self.addBtn = [[MDPopButton alloc] init];
    self.addBtn.translatesAutoresizingMaskIntoConstraints = NO;
    UIImage *btnImage = [[UIImage imageNamed:@"Add"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.addBtn setBackgroundImage:btnImage forState:UIControlStateNormal];
    [self.addBtn setBackgroundImage:btnImage forState:UIControlStateHighlighted];
    [self.addBtn addTarget:self action:@selector(pressedAddBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.addBtn.tintColor = DEFAULT_KEY_COLOR;
    [self.view addSubview:self.addBtn];
    [self.view addConstraints:@[
                                [NSLayoutConstraint constraintWithItem:self.addBtn
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0 constant:-px2p(57)],
                                [NSLayoutConstraint constraintWithItem:self.addBtn
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0 constant:0],
                                ]];
    // header
    self.headerView = [[MDBaseHeaderView alloc] initWithFrame:CGRectMake(0, 20+px2p(34), CGRectGetWidth(self.view.bounds), px2p(250))];
    [self.view addSubview:self.headerView];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (__isFirstLoad == YES) {
        
        // do app launch sequence
        [[MDAppControl sharedInstance] doAppLaunchSequenceWithCompletionBlock:^{
            
        }];
        
        
        // view is loaded
        __isFirstLoad = NO;
    }
    
}

#pragma mark - Action -
-(void)pressedAddBtn:(MDPopButton*)btn
{
    [[MDAppControl sharedInstance] setActiveListType:MDActiveListTypeToDo animated:YES completionBlock:^{
        
    }];
}

#pragma mark - UIScrollView Delegate (BaseScroller) -
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{

    // we sync scroller and headerView's view changes here
    
    // progress is 0 ... 1.
    // 0 : ToDo list is active
    // 1 : Done list is active
    CGFloat transitionProgress = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    [self.headerView layoutWithTransitionProgress:transitionProgress];
    
}


@end
