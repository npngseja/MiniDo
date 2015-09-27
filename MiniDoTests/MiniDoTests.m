//
//  MiniDoTests.m
//  MiniDoTests
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <CoreData/CoreData.h>
#import "MDUserManager.h"
#import "MDDataIO.h"

@interface MiniDoTests : XCTestCase

@end

@implementation MiniDoTests

#pragma mark - Setup Test Environment -
- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // inject a new in-memory-store-moc into MDDataIO
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[MDDataIO sharedInstance].managedObjectModel];
    [coordinator addPersistentStoreWithType: NSInMemoryStoreType
                                      configuration: nil
                                                URL: nil
                                            options: nil
                                              error: NULL];
    NSManagedObjectContext *moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [moc setPersistentStoreCoordinator:coordinator];
    [[MDDataIO sharedInstance] setManagedObjectContext:moc];
    
    
    [[MDUserManager sharedInstance] loginWithLastLoginUserWithCompletionBlock:^(BOOL succeed, MDUserObject * _Nullable user) {
        NSLog(@"[MidiDoTests] logged in with user: %@", user);
    }];
}

#pragma mark - Destroy Test Env. -
- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

#pragma mark - Test Helper -
/**
 remove all todos to help test cases
 */
-(void)clearAllToDos
{
    // user object has relationship. remove relationship will clear everything, because they are cascaded!
    MDUserObject *user = [MDUserManager sharedInstance].currentUser;
    for (MDToDoObject *todo in [user.todos allObjects]) {
        [user removeTodosObject:todo];
    }
    
}

-(void)createDummyToDosWithTexts:(NSArray<NSString*>*)texts completionBlock:(void (^)())completionBlock
{
    [self clearAllToDos];
    [self __createDummyToDosHelperWithCallCount:0 texts:texts completionBlock:^{
        if (completionBlock) {
            completionBlock();
        }
    }];
}

-(void)__createDummyToDosHelperWithCallCount:(NSInteger)count
                                        texts:(NSArray*)texts
                             completionBlock:(void (^)())completionBlock
{
    // max count reached
    if (count == texts.count) {
        if (completionBlock) {
            completionBlock();
        }
        return;
    }
    
    [[MDUserManager sharedInstance] createNewToDoForUserWithCompletionBlock:^(BOOL succeed, MDToDoObject * _Nullable todo) {
        todo.text = texts[count];
        
        NSInteger newCount = count+1;
        [self __createDummyToDosHelperWithCallCount:newCount texts:texts completionBlock:^{
            if (completionBlock) {
                completionBlock();
            }
            return;
        }];
        
    }];
}

-(void)createDummyToDosWithTexts:(NSArray<NSString*>*)texts doneStates:(NSArray<NSNumber*>*)states completionBlock:(void (^)())completionBlock
{
    [self clearAllToDos];
    [self __createDummyToDosHelperWithCallCount:0 texts:texts completionBlock:^{
        
        // now we created todos with initial state (not done)
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            for (MDToDoObject *todo in results) {
                NSInteger indexInTexts = [texts indexOfObject:todo.text];
                NSNumber *state = states[indexInTexts];
                todo.isCompleted = state;
            }
            
            if (completionBlock) {
                completionBlock();
            }
        }];
        
        
    }];
}

#pragma mark - Tests -
/**
 check if dummy todos are created correctly. we check count.
 */
-(void)testCreateDummyToDos
{
    XCTestExpectation * e = [self expectationWithDescription:@"CreateDummyToDos"];
    
    //--- GIVEN---//
    [self clearAllToDos];
    
    //--- WHEN ---//
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3"] completionBlock:^{
        
        //--- THEN---//
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"] , @"Failed");
            NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"] , @"Failed");
            NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"] , @"Failed");
            
            
            [e fulfill];
        }];
        
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

/**
 check dummy creation with pre-defined states works well
 */
-(void)testCreateDummyToDosWithPredefinedStates
{
    XCTestExpectation * e = [self expectationWithDescription:@"CreateDummyToDosWithPredefinedStates"];
    
    //--- GIVEN ---//
    [self clearAllToDos];
    
    //--- WHEN ---//
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3"] doneStates:@[@NO, @YES, @NO] completionBlock:^{
        
        //--- THEN ---//
        // fetch todos that are not done yet.
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
           
            // results should have 3, 1
            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"] , @"Failed!");
            NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"1"] , @"Failed!");
            
            [e fulfill];
       }];
        
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

-(void)testClearAllToDos
{
    XCTestExpectation * e = [self expectationWithDescription:@"ClearAllToDos"];
    
    //--- GIVEN ---//
    // make dummy todos
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3"] completionBlock:^{
        
        //--- WHEN ---//
        // remove them all
        [self clearAllToDos];
        
        //--- THEN ---//
        // fetch all todos
        [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDToDoObject class])
                                                  predicate:nil
                                            sortDescriptors:nil
                                            completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                                                
                                                NSAssert(results.count > 0, @"Clearing all todos is failed!");
                                                
                                                [e fulfill];
                                            }];

        
    }];
    
    
    
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}


/**
 logging in 10 times. DB should always have only one single user
 */
- (void)testGetLastUser
{
    XCTestExpectation * e = [self expectationWithDescription:@"GetLastUser"];
    
    //--- WHEN ---//
    [self __testGetLastUserHelperCallCount:0 lastUser:nil completionBlock:^(MDUserObject *user) {
        
        //---THEN---//
        NSAssert(user != nil, @"logged in 10 times but no user is returned???? No way...");
        
        [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDUserObject class])
                                                  predicate:nil
                                            sortDescriptors:nil
                                            completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                                       
                                                NSAssert(results.count == 1, @"There are more than 1 user!");
                                                
                                                [e fulfill];
                                            }];
        
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)__testGetLastUserHelperCallCount:(NSInteger)count
                                lastUser:(MDUserObject *)lastUser
                         completionBlock:(void (^)(MDUserObject *user))completionBlock
{
    // called 10 times. break it
    if (count == 10) {
        if (completionBlock) {
            completionBlock(lastUser);
        }
        return;
    }
    
    // increase call count
    ++count;
    
    [[MDUserManager sharedInstance] loginWithLastLoginUserWithCompletionBlock:^(BOOL succeed, MDUserObject * _Nullable user) {
        
         // recursive call
        [self __testGetLastUserHelperCallCount:count lastUser:user completionBlock:^(MDUserObject *user) {
            if (completionBlock) {
                completionBlock(user);
            }
        }];
        
    }];
}

/**
 check if fetch result contains correct todos
 */
- (void)testFetchIncompletedToDos
{
    XCTestExpectation * e = [self expectationWithDescription:@"FetchIncompletedToDos"];
    
    //---GIVEN---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4", @"5"] doneStates:@[@NO, @NO, @NO, @YES, @YES] completionBlock:^{
       // now we have [5(DONE), 4(DONE), 3(OPEN), 2(OPEN), 1(OPEN)]
        
        //--- WHEN ---//
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
           
            //--- THEN ---//
            
            // we should have [3,2,1]
            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"], @"Failed");
            NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
            NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
            NSAssert([(MDToDoObject*)results[0] isCompleted].boolValue == NO, @"Failed");
            NSAssert([(MDToDoObject*)results[1] isCompleted].boolValue == NO, @"Failed");
            NSAssert([(MDToDoObject*)results[2] isCompleted].boolValue == NO, @"Failed");
            
            [e fulfill];
            
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

/**
 check if fetch result contains correct todos
 */
- (void)testFetchCompletedToDos
{
    XCTestExpectation * e = [self expectationWithDescription:@"testFetchCompletedToDos"];
    
    //---GIVEN---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4", @"5"] doneStates:@[@YES, @YES, @YES, @NO, @NO] completionBlock:^{
        // now we have [5(OPEN), 4(OPEN), 3(DONE), 2(DONE), 1(DONE)]
        
        //--- WHEN ---//
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeDone completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            //--- THEN ---//
            
            // we should have [3,2,1]
            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"], @"Failed");
            NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
            NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
            NSAssert([(MDToDoObject*)results[0] isCompleted].boolValue == YES, @"Failed");
            NSAssert([(MDToDoObject*)results[1] isCompleted].boolValue == YES, @"Failed");
            NSAssert([(MDToDoObject*)results[2] isCompleted].boolValue == YES, @"Failed");
            
            [e fulfill];
            
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}


/**
 inserted todo should have the highest prio and should not break other prios.
 */
- (void)testInsertNewToDo {
   
    XCTestExpectation * e = [self expectationWithDescription:@"InsertNewToDo"];
    
    //--- GIVEN ---//

    // create dummy todos
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3"] completionBlock:^{
        // now we have 3, 2, 1 (3 is the highest one). the prios should be (3, 2, 1)
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            NSLog(@"[InsertNewToDo]============= Before Insert New One");
            for (MDToDoObject *t in results) {
                NSLog(@"[InsertNewToDo] - %@ (%@)", t.text, t.priority);
            }
            
            //--- WHEN ---//
            
            // insert new one with text '4'
            [[MDUserManager sharedInstance] createNewToDoForUserWithCompletionBlock:^(BOOL succeed, MDToDoObject * _Nullable todo) {
                todo.text = @"4";
                
                //--- THEN ---//
                
                // now we should have 4,3,2,1 (4 is the highest one), the prios should be (4,3,2,1)
                [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                   
                    // results is sorted descending
                    MDToDoObject *lastToDo = results[0];
                    MDToDoObject *secondLastToDo = results[1];
                    
                    NSAssert([lastToDo.text isEqualToString:@"4"], @"Last ToDo should be 4!");
                    NSAssert([secondLastToDo.text isEqualToString:@"3"], @"Second Last ToDo should be 3!");
                    NSAssert(lastToDo.priority.floatValue == 4, @"Last ToDo's Prio should be 4!");
                    NSAssert(secondLastToDo.priority.floatValue == 3, @"Second Last ToDo's prio should be 3!");
                    
                    NSLog(@"[InsertNewToDo]============= After Insert New One");
                    for (MDToDoObject *t in results) {
                        NSLog(@"[InsertNewToDo] - %@ (%@)", t.text, t.priority);
                    }
                    
                    [e fulfill];
                }];
                
                
            }];
        }];
        
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

/**
 deletion of a todo in middle of the list should ensure that fetch result should not contain that todo, and the prio should not be corrupted!
 */
- (void)testDeleteToDoInMiddle
{
    XCTestExpectation * e = [self expectationWithDescription:@"DeleteToDoInMiddle"];
    
    //--- GIVEN ---//
    
    // create dummy todos
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4"] completionBlock:^{
        // now we have 4, 3, 2, 1 (3 is the highest one). the prios should be (4, 3, 2, 1)
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            NSLog(@"[DeleteToDoInMiddle]============= Before Delete One");
            for (MDToDoObject *t in results) {
                NSLog(@"[DeleteToDoInMiddle] - %@ (%@)", t.text, t.priority);
            }
            
            //--- WHEN ---//
            
            // delete 2 (in middle of the list)
            MDToDoObject *todo = results[2];
            [[MDUserManager sharedInstance] destroyToDo:todo completionBlock:^(BOOL succeed) {
                
                //--- THEN ---//
                
                // now we should have 4,3,1 (4 is the highest one), the prios should be (4,3,1)
                [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                    
                    // results is sorted descending
                    MDToDoObject *todoWith3 = results[1];
                    MDToDoObject *todoWith1 = results[2];
                    
                    NSAssert(results.count == 3, @"ToDo is not removed?!?");
                    NSAssert(todoWith3.priority.floatValue == 3, @"ToDo with 3 should have prio with 3!");
                    NSAssert(todoWith1.priority.floatValue == 1, @"ToDo with 3 should have prio with 3!");
                    
                    NSLog(@"[DeleteToDoInMiddle]============= After Delete One");
                    for (MDToDoObject *t in results) {
                        NSLog(@"[DeleteToDoInMiddle] - %@ (%@)", t.text, t.priority);
                    }
                    
                    [e fulfill];
                }];
                
                
            }];
           
           
        }];
        
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];

}

/**
 change done state will change prios of two lists (todo and done lists). both list should be correclty modified and prios should not be corrupted.
 */
- (void)testChangeToDoDoneState
{
    XCTestExpectation * e = [self expectationWithDescription:@"ChangeToDoDoneState"];
    
    //--- GIVEN ---//
    
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"T1", @"T2", @"T3", @"D1", @"D2"] doneStates:@[@NO, @NO, @NO, @YES, @YES] completionBlock:^{
        // now we have ToDo: [T3(3), T2(2), T1(1)] and Done: [D2(5), D1(4)]
        
        //--- WHEN ---//
        
        // change T2's state to Done makes then: [T3(3), T1(1)] and [T2(6), D2(5), D(4)]
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            // pick T2
            MDToDoObject *t2 = results[1];
            
            // change its state to done
            [[MDUserManager sharedInstance] changeDoneStateOfToDo:t2 shouldChangeToDone:YES completionBlock:^(BOOL succeed) {
        
                //--- THEN ---//
                
                // check the final state of todo list
                [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                    NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"T3"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"T1"], @"Failed");
                    NSAssert([(MDToDoObject*)results[0] priority].floatValue == 3, @"Failed");
                    NSAssert([(MDToDoObject*)results[1] priority].floatValue == 1, @"Failed");
                    
                    // check the final state of done list
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeDone completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"T2"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"D2"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"D1"], @"Failed");
                        NSAssert([(MDToDoObject*)results[0] priority].floatValue == 6, @"Failed");
                        NSAssert([(MDToDoObject*)results[1] priority].floatValue == 5, @"Failed");
                        NSAssert([(MDToDoObject*)results[2] priority].floatValue == 4, @"Failed");
                        
                        [e fulfill];
                    }];
                }];
            }];
            
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

/**
 check if most import todo (highest prio) is returned correctly
 */
- (void)testGetMostImportantToDo
{
    XCTestExpectation * e = [self expectationWithDescription:@"ChangeToDoDoneState"];
    
    //--- GIVEN ---//
    
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"T1", @"T2", @"T3", @"D1", @"D2"] doneStates:@[@NO, @NO, @NO, @YES, @YES] completionBlock:^{
        // now we have todo: [T3(3), T2(2), T1(1)] and dones: [D2(5), D1(4)]
        
        //--- WHEN ---//
        
        // most import todos should be T3 and D2
        [[MDUserManager sharedInstance] mostImportantToDoForCurrentUserCompleted:NO completionBlock:^(MDToDoObject * _Nullable o) {
           
            //--- THEN ---//
            
            // should be T3
            NSAssert([o.text isEqualToString:@"T3"], @"Failed");
            
            [[MDUserManager sharedInstance] mostImportantToDoForCurrentUserCompleted:YES completionBlock:^(MDToDoObject * _Nullable o) {
               
                // should be D2
                NSAssert([o.text isEqualToString:@"D2"], @"Failed");
                
                [e fulfill];
            }];
            
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

/**
 check if change priority of a todo does not break order of new todo list
 */
- (void)testChangeToDoPriority
{
    XCTestExpectation * e = [self expectationWithDescription:@"ChangeToDoPriority"];
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4", @"5"] completionBlock:^{
        // now we have [5(5), 4(4), 3(3), 2(2), 1(1)]
        
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            //--- WHEN ---//
            
            // move 2 in between 3 and 4
            MDToDoObject *todo2 = results[3];
            MDToDoObject *todo3 = results[2];
            MDToDoObject *todo4 = results[1];
            [[MDUserManager sharedInstance] changePriorityOfToDo:todo2 greaterThanToDo:todo3 lessThanToDo:todo4 completionBlock:^(BOOL succeed) {
               
                //--- THEN ---//
                
                // we should have [5(5), 4(4), 2(3.5), 3(3), 1(1)]
                [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                    NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"5"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"4"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"2"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[3] text] isEqualToString:@"3"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[4] text] isEqualToString:@"1"], @"Failed");
                    NSAssert([(MDToDoObject*)results[0] priority].floatValue == 5, @"Failed");
                    NSAssert([(MDToDoObject*)results[1] priority].floatValue == 4, @"Failed");
                    NSAssert([(MDToDoObject*)results[2] priority].floatValue == 3.5, @"Failed");
                    NSAssert([(MDToDoObject*)results[3] priority].floatValue == 3, @"Failed");
                    NSAssert([(MDToDoObject*)results[4] priority].floatValue == 1, @"Failed");
                    
                    [e fulfill];
                    
                }];
            }];
            
        }];
        
        
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
}

@end
