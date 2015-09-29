//
//  MDDataIO.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDDataIO.h"
#import "MDDataCloudAPI.h"
#import "MDUserManager.h"

@implementation MDDataIO

+ (instancetype)sharedInstance
{
    static MDDataIO *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
       
    });
    
    return _instance;
}


- (void)saveLocalDBWithCompletionBlock:(void (^)(BOOL))completionBlock {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            
        }
        
        if (completionBlock) {
            completionBlock(error == nil ? YES : NO);
        }
    }
}

-(void)fetchObjectWithClassName:(nonnull NSString*)className
                      predicate:(nullable NSPredicate*)p
                sortDescriptors:(nullable NSArray<NSSortDescriptor*>*)s
                completionBlock:(nonnull void (^)(NSArray<MDDataObject*> * _Nullable results, NSError * _Nullable error))completionBlock
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:className];
    request.predicate = p;
    if (s.count > 0) {
        request.sortDescriptors = s;
    }
    NSError *error = nil;
    NSArray *r = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (completionBlock) {
        completionBlock(r, error);
    }

}

-(void)countObjectsWithClassName:(NSString *)className
                       predicate:(NSPredicate *)p
                 completionBlock:(void (^)(BOOL, NSInteger))completionBlock
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:className];
    request.predicate = p;
    NSError *error = nil;
    NSInteger count = [self.managedObjectContext countForFetchRequest:request error:&error];
    
    if (completionBlock) {
        completionBlock(error != nil ? NO : YES, count);
    }

}

-(void)createObjectWithClassName:(NSString *)className
                 completionBlock:(void (^)(BOOL, MDDataObject * _Nullable))completionBlock
{
    // all data objects are subclasses of MDDataObject. So this cast is safe.
    MDDataObject *o = (MDDataObject*)[NSEntityDescription
                                      insertNewObjectForEntityForName:className
                                      inManagedObjectContext:self.managedObjectContext];
    
    // set default value
    o.uniqueId = [NSUUID UUID].UUIDString;
    o.isDirty = @NO;
    o.createdAt = [NSDate date];
    o.updatedAt = [NSDate date];
    
    if (completionBlock) {
        completionBlock(o != nil ? YES : NO, o);
    }
    
    
}

-(void)deleteObject:(MDDataObject *)o completionBlock:(void (^)())completionBlock
{
    // we just mark the object as 'removed'. after sync (POST) over cloud, we remove objects from local DB
    o.isRemoved = @(YES);
    o.isDirty = @(YES);
    
    [self saveLocalDBWithCompletionBlock:^(BOOL succeed) {
        [self storeCurrentStateOnCloudWithComplectionBlock:^(BOOL succeed) {
            if (succeed) {
                // server accepted deleted todos
                // remove all todos marked as isRemoved
                [self fetchObjectWithClassName:NSStringFromClass([MDDataObject class])
                                     predicate:[NSPredicate predicateWithFormat:@"(%K == %@)", @"isRemoved", @YES]
                               sortDescriptors:nil
                               completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                                   
                                   // delete objects
                                   NSLog(@"[MDDataIO] delete objects: %ld", results.count);
                                   
                                   for (MDDataObject *o in results) {
                                       [self.managedObjectContext deleteObject:o];
                                   }
                               }];
                
            }
        }];
    }];
    if (completionBlock) {
        completionBlock();
    }
}

-(void)storeCurrentStateOnCloudWithComplectionBlock:(void (^)(BOOL))completionBlock
{
    // fetch all dirty data
    NSPredicate *p = [NSPredicate predicateWithFormat:@"(%K == %@)", @"isDirty", @YES];
    [self fetchObjectWithClassName:NSStringFromClass([MDDataObject class]) predicate:p
                   sortDescriptors:nil
                   completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                       
                       // post dirty data
                       [[MDDataCloudAPI sharedInstance] postDataArray:results
                                        ontoServerWithCompletionBlock:^(BOOL succeed, NSError * _Nullable error) {
                                        
                                            if (succeed) {
                                                NSLog(@"[MDDataIO] stored %ld objects onto cloud server!", results.count);
                                            } else {
                                                NSLog(@"[MDDataIO] storing %ld objects failed. Try it in next turn.", results.count);
                                            }
                                            if (completionBlock) {
                                                completionBlock(succeed);
                                            }
                                        
                                        }];
                   
                   }];
                       
                   
}

-(void)retrieveLastStateFromCloudWithCompletionBlock:(void (^)(BOOL))completionBlock
{
    // this call will handle conflicts between cloud and local DBs.
    [[MDDataCloudAPI sharedInstance] getAllToDosFromServerWithComplectionBlock:^(BOOL succeed, id  _Nullable response, NSError * _Nullable error) {
        
        if (error != nil) {
            NSLog(@"[MDDataIO] retrieve last state from cloud server is failed with error: %@", error);
        }
        
        // solve conflicts
        [[MDDataIO sharedInstance] solveConflictsBetweenLocalDBAndJSONServerResponse:response complectionBlock:^(BOOL succeed) {
            
            if (completionBlock) {
                completionBlock(succeed);
            }
        }];
    }];
}

-(void)__solveConflictsBetweenOldToDoList:(NSArray<MDToDoObject*>*)oldList andServerResponse:(NSMutableDictionary*)mapId2Data
{
    /*
     1. Create a empty list for dirty todo
     2. For each todo in the array:
        1) if the todo is NOT DIRTY, then update its data with server response
            - updated todo's data should be removed from server response
            - if not, store it in dirty todo list.
     3. For each todo in dirty todo list:
        1) find the nearest prev. neighbor
            - if todo is on head, then assume that prev todo has 0 prio.
            - if prev. todo in old todo list is NOT DIRTY, then pick it up as prev.
            - if not, pick prev. one in DIRTY todo
        2) find the nearest next neighbor
            - traverse old todo list in tail direction until find a next NOT DIRTY todo. pick it up as next.
            - if no NOT DIRTY is found, then assume the next todo has round(prev.prio)
        3) set todo's prio with avg. of both todos.
            - remove from server response
     
     Time Complexity: O(N) - O(N^2)
     Space Complexity: O(N)
     */
    
    /*
     - Create a empty list for dirty todo
     */
    NSMutableArray *dirtyToDos = [@[] mutableCopy];
    
    /*
     - For each todo in the array:
        - if the todo is NOT DIRTY, then update its data with server response
            - updated todo's data should be removed from server response
            - if not, store it in dirty todo list.
     */
    for (MDToDoObject *t in oldList) {
        if (t.isDirty.boolValue == NO) {
            // NOT DIRTY. update its data from server response
            NSDictionary *d = mapId2Data[t.uniqueId];
            if (d != nil) {
                // we have new data from server
                t.text = d[@"text"];
                t.priority = d[@"priority"];
                t.isCompleted = d[@"isCompleted"];
                [mapId2Data removeObjectForKey:t.uniqueId];
            }
        } else {
            // DIRTY. put this todo into dirtyToDos
            [dirtyToDos addObject:t];
        }
    }
    
    /*
     - For each todo in dirty todo list:
        - find the nearest prev. neighbor
            - if todo is on head, then assume that prev todo has 0 prio.
            - if prev. todo in old todo list is NOT DIRTY, then pick it up as prev.
            - if not, pick prev. one in DIRTY todo
        - find the nearest next neighbor
            - traverse old todo list in tail direction until find a next NOT DIRTY todo. pick it up as next.
            - if no NOT DIRTY is found, then assume the next todo has round(prev.prio)
        - set todo's prio with avg. of both todos.
        - remove from server response
     */
    // dirtyToDos is already sorted by prios desc.
    for (MDToDoObject *t in dirtyToDos) {
        // find lower bound (prev todo)
        CGFloat prioLowerBound = 0;
        NSInteger indexOfToDoInEntireList = [oldList indexOfObject:t];
        NSInteger indexOfToDoLowerBound = indexOfToDoInEntireList-1;
        if (indexOfToDoLowerBound >= 0) {
            MDToDoObject *lowerBoundToDoCandidate = oldList[indexOfToDoLowerBound];
            if (lowerBoundToDoCandidate.isDirty.boolValue == NO) {
                prioLowerBound = lowerBoundToDoCandidate.priority.floatValue;
            } else {
                // take prio from dirtyToDo list
                NSInteger indexOfToDoInDirtyToDoList = [dirtyToDos indexOfObject:t];
                indexOfToDoLowerBound = indexOfToDoInDirtyToDoList-1;
                if (indexOfToDoLowerBound >= 0) {
                    lowerBoundToDoCandidate = dirtyToDos[indexOfToDoLowerBound];
                    prioLowerBound = lowerBoundToDoCandidate.priority.floatValue;
                } else {
                    // prioLowerBound should be 0. it is already set
                }
            }
        } else {
            // prioLowerBound should be 0. it is already set
        }
        
        
        // find upper bound (next todo)
        CGFloat prioUpperBound = round(prioLowerBound)+1;
        NSInteger indexOfToDoUpperBound = indexOfToDoInEntireList+1;
        if (indexOfToDoUpperBound < oldList.count) {
            MDToDoObject *upperBoundToDoCandidate = oldList[indexOfToDoUpperBound];
            if (upperBoundToDoCandidate.isDirty.boolValue == NO) {
                prioUpperBound = upperBoundToDoCandidate.priority.floatValue;
            } else {
                // traverse oldList until find next NOT DIRTY todo
                NSInteger currentIndex = indexOfToDoInEntireList+1;
                while (currentIndex < oldList.count) {
                    MDToDoObject *candidate = oldList[currentIndex];
                    if (candidate.isDirty.boolValue == NO) {
                        prioUpperBound = candidate.priority.floatValue;
                        break;
                    }
                    ++currentIndex;
                }
                // if no NOT DIRTY todo is found, then we use its default.
            }
        } else {
            // prioUpperBound is already set.
        }
        
        // now we have lower and upper bound.
        // calc avg. and set it as new prio
        t.priority = @((prioUpperBound+prioLowerBound)/2);
        [mapId2Data removeObjectForKey:t.uniqueId];
    }

}

-(void)solveConflictsBetweenLocalDBAndJSONServerResponse:(nullable NSDictionary*)mapId2Data
                                        complectionBlock:(nullable void (^)(BOOL))completionBlock
{
    if (mapId2Data == nil) {
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
    /* Rule:
     
     - if a todo is clean (NOT dirty) then overwrite it with server data
     - if a todo is DIRTY (this means user modified it before we get server response), we DO NOT overwrite it (the app is for a private use. user's modification is more important than server's one).
     - dirty todos should have correct prios regarding new prios received from server
     - those dirty todos should stay as dirty, in order to update server later!
     - we need to do some test if this approach works fine. See unit test codes to test several cases!
     
     Algorithm
     
     For a list of open todos:
     1. Fetch all todos and store them in an array (sorted by prios ascend.)
     2. Create a empty list for dirty todo
     3. For each todo in the array:
        1) if the todo is NOT DIRTY, then update its data with server response
            - updated todo's data should be removed from server response
            - if not, store it in dirty todo list.
     4. For each todo in dirty todo list:
        1) find the nearest prev. neighbor
            - if todo is on head, then assume that prev todo has 0 prio.
            - if prev. todo in old todo list is NOT DIRTY, then pick it up as prev.
            - if not, pick prev. one in DIRTY todo
        2) find the nearest next neighbor
            - traverse old todo list in tail direction until find a next NOT DIRTY todo. pick it up as next.
            - if no NOT DIRTY is found, then assume the next todo has round(prev.prio)
        3) set todo's prio with avg. of both todos.
            - remove from server response
     5. For a list of done todos: Do 1-4 with remaining server response
     6. Done.
     */
    
    NSMutableDictionary *mutableMapId2Data = [mapId2Data mutableCopy];
    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo sortedDescending:NO completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
        
        if (succeed == NO) {
            if (completionBlock) {
                completionBlock(NO);
            }
            return ;
        }
        
        // solve conflict of open todos
        [self __solveConflictsBetweenOldToDoList:results andServerResponse:mutableMapId2Data];
        
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeDone sortedDescending:NO completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
           
            if (succeed == NO) {
                if (completionBlock) {
                    completionBlock(NO);
                }
                return ;
            }

            // solve conflicts of done todos
            // note that mapId2Data is modified in the previous call!
            [self __solveConflictsBetweenOldToDoList:results andServerResponse:mutableMapId2Data];
            
            // remaining todos in mutableMapId2Data is new from server. add it

            // WE REALLY SHOULD DO THIS PROCESS IN BACKGROUND......
            for (NSString *uid in [mutableMapId2Data allKeys]) {
                [self createNewToDoWithUniqueId:uid serverResponseDict:mutableMapId2Data[uid]];
            }
            
            // done!
            if (completionBlock) {
                completionBlock(YES);
            }
            
        }];
    }];

}

// I really want to make this process in a background thread....
-(void)createNewToDoWithUniqueId:(NSString*)uid serverResponseDict:(NSDictionary*)dict
{
    // all data objects are subclasses of MDDataObject. So this cast is safe.
    MDToDoObject *o = (MDToDoObject*)[NSEntityDescription
                                      insertNewObjectForEntityForName:NSStringFromClass([MDToDoObject class])
                                      inManagedObjectContext:self.managedObjectContext];
    
    // set default value
    o.uniqueId = uid;
    o.isDirty = @NO;
    o.createdAt = [NSDate date];
    o.updatedAt = [NSDate date];
    o.text = dict[@"text"];
    o.priority = dict[@"priority"];
    o.isCompleted = dict[@"isCompleted"];
    

}


#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "MD.MiniDo" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"MiniDo" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"MiniDo.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}


@end
