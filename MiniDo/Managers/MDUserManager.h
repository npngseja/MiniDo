//
//  MDUserManager.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MDUserObject.h"
#import "MDToDoObject.h"
#import "MDMiniDoConstants.h"
@interface MDUserManager : NSObject

@property (nullable, atomic, strong) MDUserObject *currentUser;
@property NSInteger maximumAllowedToDoCount;

/**
 return singleton instance
 
 @return shared instance
 */
+ (nonnull instancetype)sharedInstance;

#pragma mark - User Management -

/**
 fetch last logged in user. If nothing exists, create new one. Then make an attempt to log in on server (pretend it) If we want to have a real login function on cloud server, we need more complex login process.
 */
-(void)loginWithLastLoginUserWithCompletionBlock:(nullable void (^)(BOOL succeed, MDUserObject * _Nullable user))completionBlock;

#pragma mark - ToDo Management -
/**
 create a new todo object and set current user its owner. This will not be synced over cloud because its empty
 */
-(void)createNewToDoForUserWithCompletionBlock:(nonnull void (^)(BOOL succeed, MDToDoObject * _Nullable todo))completionBlock;

/**
 destroy a todo object
 */
-(void)destroyToDo:(nonnull MDToDoObject*)todo
   completionBlock:(nullable void (^)(BOOL succeed))completionBlock;

/**
 fetch and return todos
 */
-(void)fetchTodosForListType:(MDActiveListType)listType
             completionBlock:(nonnull void (^)(BOOL succeed, NSArray<MDToDoObject*> * _Nullable results))completionBlock;
-(void)fetchTodosForListType:(MDActiveListType)listType
            sortedDescending:(BOOL)descending
             completionBlock:(nonnull void (^)(BOOL succeed, NSArray<MDToDoObject*> * _Nullable results))completionBlock;

/**
 count of all todo
 */
-(void)countOfAllToDosWithCompletionBlock:(nullable void (^)(BOOL succeed, NSInteger count))completionBlock;

/** 
 get last state of todos from server and merge them into local db
 */
-(void)getAndMergeLastToDoStateFromServerWithComplectionBlock:(nullable void (^)(BOOL succeed))completionBlock;
/**
 return the most important todo (highest priority)
 @param completed
        if YES, it returns most important todo which is done (vice versa)
 */
-(void)mostImportantToDoForCurrentUserCompleted:(BOOL)completed completionBlock:(nullable void (^)(MDToDoObject * _Nullable o))completionBlock;

/**
 change todo's isCompleted attribute. This will change its priority on target list
 */
-(void)changeDoneStateOfToDo:(nonnull MDToDoObject *)todo
          shouldChangeToDone:(BOOL)isDone
             completionBlock:(nullable void (^)(BOOL succeed))completionBlock;

/**
 change priority of todo using information about its prev and next todos. if prevToDo is nil, then current todo should have lowest prio. if nextTodo is nil. current todo should have highest prio. if prevToDo and nextToDo are nil, it fails!
 */
-(void)changePriorityOfToDo:(nonnull MDToDoObject *)todo
            greaterThanToDo:(nullable MDToDoObject *)prevToDo
               lessThanToDo:(nullable MDToDoObject* )nextToDo completionBlock:(nullable void (^)(BOOL succeed))completionBlock;

@end
