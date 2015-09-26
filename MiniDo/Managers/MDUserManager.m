//
//  MDUserManager.m
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDUserManager.h"
#import "MDDataIO.h"
#import "MDUserObject.h"

@implementation MDUserManager

+ (nonnull instancetype)sharedInstance;
{
    static MDUserManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
        
    });
    
    return _instance;
}

-(void)loginWithLastLoginUserWithCompletionBlock:(void (^)(BOOL, MDUserObject * _Nullable))completionBlock
{
    [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDUserObject class]) predicate:nil sortDescriptors:nil completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
        
        if (error != nil) {
            // error occurred
            if (completionBlock) {
                completionBlock(NO, nil);
            }
            return;
            
        } else {
            // fetch succeed
            if (results.count == 0) {
                // no object is found
                // create a new user object
                [[MDDataIO sharedInstance] createObjectWithClassName:NSStringFromClass([MDUserObject class]) completionBlock:^(BOOL succeed, MDDataObject * _Nullable object) {
                    
                    MDUserObject *user = (MDUserObject*)object;
                    NSLog(@"[MDUserManager] created a user: %@", user.uniqueId);
                    
                    [[MDDataIO sharedInstance] saveInBackgroundWithCompletionBlock:nil];
                    
                    self.currentUser = user;
                    
                    if (completionBlock) {
                        completionBlock(succeed, user);
                    }
                    
                }];
            } else {
                // object is found
                MDUserObject *user = (MDUserObject*)[results lastObject];
                NSLog(@"[MDUserManager] found a user %@", user.uniqueId);
                
                self.currentUser = user;
                
                if (completionBlock) {
                    completionBlock(YES, user);
                }
                return;
            }
        }
        
    }];
}

-(void)createNewToDoForUserWithCompletionBlock:(void (^)(BOOL, MDToDoObject * _Nullable))completionBlock
{
    
    if (self.currentUser == nil) {
        // no user is set. failed
        if (completionBlock) {
            completionBlock(NO, nil);
        }
        return;
    }
    
    // we have user
    
    // create a new todo item
    [[MDDataIO sharedInstance] createObjectWithClassName:NSStringFromClass([MDToDoObject class]) completionBlock:^(BOOL succeed, MDDataObject * _Nullable object) {
        if (succeed == NO) {
            if (completionBlock) {
                completionBlock(NO, nil);
            }
            return;
            
        } else {
            MDToDoObject *todo = (MDToDoObject*)object;
            todo.isDirty = @(YES);  // this todo is new on local, server does not knows about it. we set it dirty.
            
            // set the order of this todo with current todo count of the user
            // larger := newer. it starts with 0
            todo.order = self.currentUser.todoCount;
            
            // set it user's todo
            // it is ordered set!
            [self.currentUser addTodosObject:todo];
            
            // increase todoCount
            self.currentUser.todoCount = @(self.currentUser.todoCount.integerValue + 1);
            
            
            if (completionBlock) {
                completionBlock(YES, todo);
            }
            return;
            
        }
        
    }];
}

-(void)destroyToDo:(MDToDoObject *)todo completionBlock:(void (^)(BOOL))completionBlock
{
    //ToDo: consider order change of all 
    [[MDDataIO sharedInstance] deleteObject:todo completionBlock:^{
        if (completionBlock) {
            completionBlock(YES);
        }
    }];
}

-(void)fetchTodosForListType:(MDActiveListType)listType
             completionBlock:(nonnull void (^)(BOOL succeed, NSArray<MDToDoObject*> * _Nullable results))completionBlock;
{
    BOOL isCompleted = listType == MDActiveListTypeToDo ? NO : YES;
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == %@)", @"isCompleted", @(isCompleted), @"owner", self.currentUser];
    NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:NO];
    [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDToDoObject class])
                                              predicate:p
                                        sortDescriptors:@[s]
                                        completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                                            
                                            if (completionBlock) {
                                                completionBlock(error == nil ? YES : NO, (NSArray<MDToDoObject*>*)results);
                                            }
        
    }];
}


@end
