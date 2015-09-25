//
//  MDUserManager.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDUserObject.h"
#import "MDToDoObject.h"
#import "MDMiniDoConstants.h"
@interface MDUserManager : NSObject

@property (nullable, atomic, strong) MDUserObject *currentUser;

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


@end
