//
//  MDAppControl.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDMiniDoConstants.h"
#import "MDToDoObject.h"

@class MDBaseViewController;

@interface MDAppControl : NSObject

@property (readonly, weak) MDBaseViewController *baseVc;

/**
 currently visible list type
 */
@property MDActiveListType activeListType;

/**
 if a todo item is focused or not
 */
@property (readonly) BOOL isFocusMode;

/**
 return singleton instance
 
 @return shared instance
 */
+ (nonnull instancetype)sharedInstance;

/**
 application launch sequence
 */
- (void)doAppLaunchSequenceWithCompletionBlock:(nullable void (^)())completionBlock;

/**
 will change app layout for the target active list type
 */
- (void)setActiveListType:(MDActiveListType)activeListType
                 animated:(BOOL)animated
          completionBlock:(nullable void (^)())completionBlock;

/**
 insert a new ToDo Item into the todoList. The Item has no data, and will be ready to get user's input
 */
- (void)insertNewToDoItemOnToDoList;

/**
 remove a todo item from a list
 */
- (void)removeToDoItemWithToDo:(nonnull MDToDoObject*)todo;

/**
 move todo item from source list to target list. The item will be inserted on top of the target list
 */
- (void)moveToDo:(nonnull MDToDoObject*)todo sourceListType:(MDActiveListType)sourceListType targetListType:(MDActiveListType)targetListType completionBlock:(nullable void (^)())completionBlock;

/**
 focus on todo item
 */
- (void)focusOnToDo:(nonnull MDToDoObject*)todo completionBlock:(nullable void (^)())completionBlock;

/**
 dismiss focussing todo
 */
-(void)dismissCurrentFocusToDoWithCompletionBlock:(nullable void (^)())completionBlock;

/**
 force to dismiss focus mode. this is useful when a todo is deleted in focus mode. this method will remove overlay blocking UI while focus mode.
 */
-(void)forceToDismissFocusModeWithCompletionBlock:(nullable void (^)())completionBlock;

/**
 !!WARNING!! ----- block entire UI. do not accept any touch event. this is useful to block UI while commiting animation.
 this method can make entire UI freeze. Have a thought once more, when you invoke this method!
 */
-(void)blockEntireUI;
-(void)unblockEntireUI;

@end
