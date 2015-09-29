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
#import "MDMiniDoConstants.h"
#import "MDAppControl.h"

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

-(instancetype)init
{
    self = [super init];
    
    if (self) {
        self.maximumAllowedToDoCount = MAX_TODO_COUNT;
    }
    
    return self;
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
                    
                    [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:nil];
                    
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
    
    // check if maximum count is reached
    [self countOfAllToDosWithCompletionBlock:^(BOOL succeed, NSInteger count) {
       
        if (succeed == NO) {
            if (completionBlock) {
                completionBlock(NO, nil);
            }
            return;
        }
        
        if (count == MAX_TODO_COUNT) {
            // reached. do not create new todo
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:NSLocalizedString(@"You have too many todos. Please delete some!", nil) preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"Ok", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                
            }];
            
            [alert addAction:ok];
            
            UIViewController *baseVc = (UIViewController*)[MDAppControl sharedInstance].baseVc;
            
            [baseVc presentViewController:alert animated:YES completion:nil];

            return;
        }
        
        
        // we can create new todo
        // create a new todo item
        [[MDDataIO sharedInstance] createObjectWithClassName:NSStringFromClass([MDToDoObject class]) completionBlock:^(BOOL succeed, MDDataObject * _Nullable object) {
            if (succeed == NO) {
                if (completionBlock) {
                    completionBlock(NO, nil);
                }
                return;
                
            } else {
                MDToDoObject *todo = (MDToDoObject*)object;
                
                // get todo with the highest priority
                [self mostImportantToDoForCurrentUserCompleted:NO completionBlock:^(MDToDoObject *o) {
                    CGFloat highestPrio = 0.0;
                    if (o != nil) {
                        highestPrio = o.priority.floatValue;
                    }
                    
                    // if last prio is 2.0 then new one will be 3.0
                    // if last prio is 1.3 then new one will be 2.0
                    // if last prio is 1.9 then new one will be 3.0
                    CGFloat newPrio = round(highestPrio)+1;
                    
                    // set the order of this todo with current todo count of the user
                    // larger := higher priority. it starts with 1.0
                    todo.priority = @(newPrio);
                    todo.isDirty = @(YES);
                    
                    // set it user's todo
                    // it is ordered set!
                    [self.currentUser addTodosObject:todo];
                    
                    if (completionBlock) {
                        completionBlock(YES, todo);
                    }
                    return;
                    
                }];
                
            }
            
        }];
        
        
        
        
    }];
    
    
}

-(void)destroyToDo:(MDToDoObject *)todo completionBlock:(void (^)(BOOL))completionBlock
{
    [[MDDataIO sharedInstance] deleteObject:todo completionBlock:^{
        if (completionBlock) {
            completionBlock(YES);
        }
    }];
}

-(void)fetchTodosForListType:(MDActiveListType)listType
             completionBlock:(nonnull void (^)(BOOL succeed, NSArray<MDToDoObject*> * _Nullable results))completionBlock
{
    [self fetchTodosForListType:listType sortedDescending:YES completionBlock:completionBlock];
}

-(void)fetchTodosForListType:(MDActiveListType)listType
            sortedDescending:(BOOL)descending
             completionBlock:(nonnull void (^)(BOOL succeed, NSArray<MDToDoObject*> * _Nullable results))completionBlock
{
    BOOL isCompleted = listType == MDActiveListTypeToDo ? NO : YES;
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == %@) AND (%K == %@)", @"isCompleted", @(isCompleted), @"owner", self.currentUser, @"isRemoved", @NO];
    NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:!descending];
    [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDToDoObject class])
                                              predicate:p
                                        sortDescriptors:@[s]
                                        completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                                            
                                            if (completionBlock) {
                                                completionBlock(error == nil ? YES : NO, (NSArray<MDToDoObject*>*)results);
                                            }
        
    }];
}

-(void)countOfAllToDosWithCompletionBlock:(void (^)(BOOL, NSInteger))completionBlock
{
    [[MDDataIO sharedInstance] countObjectsWithClassName:NSStringFromClass([MDToDoObject class])
                                               predicate:[NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == %@)", @"owner", self.currentUser, @"isRemoved", @NO]
                                         completionBlock:^(BOOL succeed, NSInteger count) {
    
                                             if (completionBlock) {
                                                 completionBlock(succeed, count);
                                             }
                                         }];
}

-(void)getAndMergeLastToDoStateFromServerWithComplectionBlock:(void (^)(BOOL))completionBlock
{
    [[MDDataIO sharedInstance] retrieveLastStateFromCloudWithCompletionBlock:^(BOOL succeed) {
        if (completionBlock) {
            completionBlock(succeed);
        }
    }];
}

-(void)mostImportantToDoForCurrentUserCompleted:(BOOL)completed
                                completionBlock:(nullable void (^)(MDToDoObject * _Nullable o))completionBlock
{
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == %@)", @"isCompleted", @(completed), @"owner", self.currentUser];
    NSSortDescriptor *s = [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO];
    [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDToDoObject class]) predicate:p sortDescriptors:@[s] completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
        MDToDoObject *todo = nil;
        if (results.count > 0) {
            todo = (MDToDoObject*)results[0];
        }
        
        if (completionBlock) {
            completionBlock(todo);
        }
    }];
}

-(void)changeDoneStateOfToDo:(nonnull MDToDoObject *)todo
          shouldChangeToDone:(BOOL)isDone
             completionBlock:(nullable void (^)(BOOL succeed))completionBlock
{
    // change priority
    // we find most important todo in target list. after that we insert new todo into the target list
    [self mostImportantToDoForCurrentUserCompleted:isDone completionBlock:^(MDToDoObject * _Nullable o) {
        
        // calc new prio
        CGFloat highestPrio = 0.0;
        if (o != nil) {
            highestPrio = o.priority.floatValue;
        }
        // if last prio is 2.0 then new one will be 3.0
        // if last prio is 1.3 then new one will be 2.0
        // if last prio is 1.9 then new one will be 3.0
        CGFloat newPrio = round(highestPrio)+1;
        
        // update todo data
        // set the order of this todo with current todo count of the user
        // larger := higher priority. it starts with 1.0
        todo.priority = @(newPrio);
        todo.isCompleted = @(isDone);
        if (isDone) {
            todo.completionDate = [NSDate date];
        } else {
            todo.creationDate = [NSDate date];
        }
        todo.isDirty = @(YES);
        
        [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
            [[MDDataIO sharedInstance] storeCurrentStateOnCloudWithComplectionBlock:^(BOOL succeed) {
                if (completionBlock) {
                    completionBlock(succeed);
                }
            }];
            
        }];
        
        

    }];
    

}

-(void)changePriorityOfToDo:(MDToDoObject *)todo
            greaterThanToDo:(MDToDoObject *)prevToDo
               lessThanToDo:(MDToDoObject *)nextToDo
            completionBlock:(void (^)(BOOL))completionBlock
{
    
    NSNumber *maxPrio = nextToDo ? nextToDo.priority : nil;
    NSNumber *minPrio = prevToDo ? prevToDo.priority : nil;
    
    CGFloat newPrio = -1;
    if (maxPrio != nil && minPrio != nil) {
        newPrio = (maxPrio.floatValue+minPrio.floatValue)/2;
    } else if (maxPrio == nil && minPrio != nil) {
        // no next todo
        newPrio = round(minPrio.floatValue) + 1;
    } else if (maxPrio != nil && minPrio == nil) {
        // no prev todo
        newPrio = floor(maxPrio.floatValue) -1;
    } else {
        // error!
        if (completionBlock) {
            completionBlock(NO);
        }
    }
    
    todo.priority = @(newPrio);
    todo.isDirty = @(YES);
    
    [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
        
        // store this change over cloud!
        [[MDDataIO sharedInstance] storeCurrentStateOnCloudWithComplectionBlock:^(BOOL succeed) {
            
        }];
        
        // this completion block is out of the completionBlock of the call above,
        // because store over cloud will happen in background.
        if (completionBlock) {
            completionBlock(succeed);
        }
        
    }];
}

@end
