//
//  MDAppControl.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDAppControl.h"
#import "MDBaseViewController.h"
#import "AppDelegate.h"
#import "MDUserManager.h"
#import "MDDataIO.h"

@implementation MDAppControl
{
    MDToDoObject *__currentFocusToDo;
}
@synthesize activeListType = _activeListType;

+ (nonnull instancetype)sharedInstance;
{
    static MDAppControl *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    
    return _instance;
}

-(instancetype)init
{
    self = [super init];
    
    if (self) {
        _baseVc = [(AppDelegate*)[UIApplication sharedApplication].delegate baseVc];
        
        // initial list type is ToDo List
        _activeListType = MDActiveListTypeToDo;
        _isFocusMode = NO;
    }
    
    return self;
}

#pragma mark - UI Control -
-(void)blockEntireUI
{
    self.baseVc.view.userInteractionEnabled = NO;
}

-(void)unblockEntireUI
{
    self.baseVc.view.userInteractionEnabled = YES;
}

#pragma mark - App Launch Sequence -
- (void)doAppLaunchSequenceWithCompletionBlock:(nullable void (^)())completionBlock
{
    /*
     In order to make the app super super simple, I make following Assumptions:
     - We do not have username/password. We do not have login UI. User sees immediately todo list without logging in.
     - User object is created with UUID and stored on local DB. The User object will be stored on cloud. Since we do not have real server, we skip sign up process. We assume the the User object is already stored on server, and he is already granted to get his/her data from server.
     */
    
    __weak typeof(self) weakSelf = self;
    
    // 1. get last user. if it does not exist, we create new one.
    [[MDUserManager sharedInstance] loginWithLastLoginUserWithCompletionBlock:^(BOOL succeed, MDUserObject * _Nullable user) {
        
        if (succeed == YES) {
            // user logged in
            
            // set active list to ToDo List
            
            [self setActiveListType:MDActiveListTypeToDo animated:NO completionBlock:^{
                
                // load both table views with todos from DB
                [weakSelf.baseVc.todoListViewController updateListViewWithCurrentTodo];
                [weakSelf.baseVc.doneListViewController updateListViewWithCurrentTodo];
                
                // retrieve last todos from server
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    if (succeed) {
                        // update todo lists again.
                        [weakSelf.baseVc.todoListViewController updateListViewWithCurrentTodo];
                        [weakSelf.baseVc.doneListViewController updateListViewWithCurrentTodo];
                    }
                }];
                
            }];
            
        } else {
            // login failed
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Something went wrong. Restart might fix the problem. Sorry!", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            [self.baseVc presentViewController:alert animated:YES completion:nil];
            
        }
        
        if (completionBlock) {
            completionBlock();
        }
        
    }];
    
}

#pragma - Active List Type Change -
-(MDActiveListType)activeListType
{
    return _activeListType;
}

-(void)setActiveListType:(MDActiveListType)activeListType
{
    [self setActiveListType:activeListType animated:NO completionBlock:nil];
}

- (void)setActiveListType:(MDActiveListType)activeListType
                 animated:(BOOL)animated
          completionBlock:(nullable void (^)())completionBlock
{
    _activeListType = activeListType;
    
    // change base scroller (containing two todo lists) layout
    // header view is linked with the scroller via -(void)scrollViewDidScroll:, so we do not need to control here.
    CGFloat newContentOffsetX = (activeListType == MDActiveListTypeToDo) ? 0 : CGRectGetWidth(_baseVc.scroller.bounds);
    [_baseVc.scroller setContentOffset:CGPointMake(newContentOffsetX, 0) animated:animated];
    
    if (completionBlock) {
        completionBlock();
    }
}

#pragma mark - ToDo Item Management -
-(void)insertNewToDoItemOnToDoList
{
    [[MDUserManager sharedInstance] createNewToDoForUserWithCompletionBlock:^(BOOL succeed, MDToDoObject * _Nullable todo) {
        
        if (succeed == NO) {
            // failed. we notify user only when maximum todo count is reached. otherwise we do not notify it, because it would happen very seldom and user will then try to tap the button again.
            //TODO: count all todos here
            
        } else {
            // new empty todo is added
            [self.baseVc.todoListViewController insertNewToDoCellWithToDoObject:todo animated:YES];
            
        }

        
    }];
    
}

-(void)removeToDoItemWithToDo:(MDToDoObject *)todo
{
    MDToDoListViewController *targetVc = nil;
    if (todo.isCompleted.boolValue == NO) {
        // this item (cell) is in todolist
        targetVc = self.baseVc.todoListViewController;
    } else {
        // in done list
        targetVc = self.baseVc.doneListViewController;
    }
    
    [targetVc removeToDoCellWithToDoObject:todo animated:YES completionBlock:^{
        // we removed cell. Next is destroying todo object. be careful reordering here!
        [[MDUserManager sharedInstance] destroyToDo:todo completionBlock:^(BOOL succeed) {
            
        }];
    }];

}

-(void)moveToDo:(MDToDoObject *)todo sourceListType:(MDActiveListType)sourceListType targetListType:(MDActiveListType)targetListType completionBlock:(void (^)())completionBlock
{
    BOOL flyOverAni = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? YES : NO;
    [self.baseVc moveToDo:todo sourceListType:sourceListType targetListType:targetListType flyOverAnimation:flyOverAni completionBlock:^{
        if (completionBlock) {
            completionBlock();
        }
    }];
}

-(void)focusOnToDo:(MDToDoObject *)todo completionBlock:(void (^)())completionBlock
{
    __currentFocusToDo = todo;
    _isFocusMode = YES;
    NSLog(@"[MDAppControl] focus on todo: %@", todo.text);
    [self.baseVc focusOnToDo:todo completionBlock:^(BOOL succeed) {
        if (completionBlock) {
            completionBlock();
        }
    }];
    
    
}

-(void)dismissCurrentFocusToDoWithCompletionBlock:(void (^)())completionBlock
{
    if (__currentFocusToDo == nil) {
        // we do not have any focussed todo
        return;
    }
    
    MDToDoObject *todo = __currentFocusToDo;
    __currentFocusToDo = nil;
    _isFocusMode = NO;
    [self.baseVc dismissToDoFocus:todo completionBlock:^(BOOL succeed) {
        if (succeed == NO) {
            // failed. restore last state
            __currentFocusToDo = todo;
            _isFocusMode = YES;
        }
        
        if (completionBlock) {
            completionBlock();
        }
    }];
    
}

-(void)forceToDismissFocusModeWithCompletionBlock:(void (^)())completionBlock
{
    _isFocusMode = NO;
    [self.baseVc forceToDismissFocusModeWithCompletionBlock:^{
        if (completionBlock) {
            completionBlock();
        }
    }];
}

@end
