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

@implementation MDAppControl
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
    }
    
    return self;
}

#pragma mark - App Launch Sequence -
- (void)doAppLaunchSequenceWithCompletionBlock:(nullable void (^)())completionBlock
{
    // set active list to ToDo List
    [self setActiveListType:MDActiveListTypeToDo animated:NO completionBlock:^{
        
    }];
    
    if (completionBlock) {
        completionBlock();
    }
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
    [self.baseVc.todoListViewController insertNewToDoCellAnimated:YES];
}

@end
