//
//  MiniDoTests.m
//  MiniDoTests
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import <CoreData/CoreData.h>
#import "MDUserManager.h"
#import "MDDataIO.h"
#import "MDDataCloudAPI.h"

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

/**
 check if todo deletion is correctly synced over cloud
 */
-(void)testDeleteToDoWhenCloudSyncSuccessful
{
   /*
    Deletion:
    1. set isRemoved = YES (do not delete it)
    2. sync over cloud (general server sync method)
    3. if successful, delete the todo from local DB
    */
    
    XCTestExpectation * e = [self expectationWithDescription:@"DeleteToDoWhenCloudSyncSuccessful"];
   
    
    //--- GIVEN ---//
    // [1, 2, 3, 4(to be deleted)]
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4"] completionBlock:^{
       [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
           MDToDoObject *todo4 = results[0];
           
           //-- WHEN --//
           // we delete todo4 and it was successful
           // we need a bit of mocking
           id mockedAPI = [OCMockObject niceMockForClass:[MDDataCloudAPI class]];
           [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
               void (^completionBlock)(BOOL succeed, NSError * _Nullable error);
               
               [invocation getArgument:&completionBlock atIndex:3];
               
               // we pretend it is successful
               completionBlock(YES, nil);
               
           }] postDataArray:OCMOCK_ANY ontoServerWithCompletionBlock:OCMOCK_ANY];
           [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
           
           // delete todo4
           [[MDUserManager sharedInstance] destroyToDo:todo4 completionBlock:^(BOOL succeed) {
               
               // stop mocking
               [mockedAPI stopMocking];
               
               //-- THEN --//
               // we should have [3, 2, 1]
               [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                  
                   NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"], @"Failed");
                   NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
                   NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
                   
                   [e fulfill];
               }];
               
              
           }];
           
           
       }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
    
}

/**
 todo deletion synced over cloud is failed --> those todos should stay on local DB, but fetching todos should return array excluding them.
 */
-(void)testDeleteToDoWhenCloudSyncFailed
{
    /*
     Deletion:
     1. set isRemoved = YES (do not delete it)
     2. sync over cloud (general server sync method)
     3. if failed, those todos are remaining in local DB marked as isRemoved
     */
    
    XCTestExpectation * e = [self expectationWithDescription:@"testDeleteToDoWhenCloudSyncFailed"];
    
    
    //--- GIVEN ---//
    // [1, 2, 3, 4(to be deleted)]
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            MDToDoObject *todo3 = results[1];
            
            //-- WHEN --//
            // we delete todo3 and it was failed!
            // we need a bit of mocking
            id mockedAPI = [OCMockObject niceMockForClass:[MDDataCloudAPI class]];
            [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                void (^completionBlock)(BOOL succeed, NSError * _Nullable error);
                
                [invocation getArgument:&completionBlock atIndex:3];
                
                // we pretend it is failed!
                completionBlock(NO, nil);
                
            }] postDataArray:OCMOCK_ANY ontoServerWithCompletionBlock:OCMOCK_ANY];
            [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
            
            // delete todo4
            [[MDUserManager sharedInstance] destroyToDo:todo3 completionBlock:^(BOOL succeed) {
                
                // stop mocking
                [mockedAPI stopMocking];
                
                //-- THEN --//
                // we should have [4, 3(deleted), 2, 1] in local DB
                [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDToDoObject class]) predicate:[NSPredicate predicateWithFormat:@"(%K == %@) AND (%K == %@)", @"owner", [MDUserManager sharedInstance].currentUser, @"isCompleted", @NO] sortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:NO]] completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                    
                    NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"3"], @"Failed");
                    NSAssert([(MDToDoObject*)results[1] isRemoved].boolValue == YES, @"Failed");
                    NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"2"], @"Failed");
                    NSAssert([[(MDToDoObject*)results[3] text] isEqualToString:@"1"], @"Failed");
                    
                    // but normal fetch should return [4,2,1]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
                        
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
 after post todos, all todos should be marked as clean (isDirty = NO)
 */
-(void)testPostToDo {
    XCTestExpectation * e = [self expectationWithDescription:@"PostToDo"];
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3"] completionBlock:^{
       // now we have [3(dirty), 2(dirty), 1(dirty)]
        
        //--- WHEN ---//
        // we post those dirty todos
        
        [[MDDataIO sharedInstance] storeCurrentStateOnCloudWithComplectionBlock:^(BOOL succeed) {
            [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                
                //--- THEN ---//
                // we have 3 todos and there should be no dirty todos!
                NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"], @"Failed");
                NSAssert([(MDToDoObject*)results[0] isDirty].boolValue == NO, @"Failed");
                NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
                NSAssert([(MDToDoObject*)results[1] isDirty].boolValue == NO, @"Failed");
                NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
                NSAssert([(MDToDoObject*)results[2] isDirty].boolValue == NO, @"Failed");
                
                [e fulfill];
            }];
        }];
    }];
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
    
}

/**
 we've got todos from server, but some of them is modified by user before server response. in this case, we should preserve user's intention and try to push the new text onto server in next turn
 */
-(void)testGetToDosWithDifferentTextButWithSamePrios
{
    XCTestExpectation * e = [self expectationWithDescription:@"GetToDosWithDifferentTextButWithSamePrios"];
    
    // we have on local these todos: [4(clean), 3(clean), 2(dirty), 1(clean)]
    // then we've got todos from server: [M4, M3, M2, M1]
    // the merge result should be [M4, M3, 2, M1]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4"] completionBlock:^{
       [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
          
           MDToDoObject *t4 = (MDToDoObject*)results[0];
           t4.isDirty = @NO;
           MDToDoObject *t3 = (MDToDoObject*)results[1];
           t3.isDirty = @NO;
           MDToDoObject *t2 = (MDToDoObject*)results[2];
           t2.isDirty = @YES;
           MDToDoObject *t1 = (MDToDoObject*)results[3];
           t1.isDirty = @NO;
           
           [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
               // now we have  [4(clean), 3(clean), 2(dirty), 1(clean)] in local DB
               
               //--- WHEN ---//
               // we've got server response: [M4, M3, M2, M1]
               // we need to mock
               MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
               id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
               [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                   void (^completionBlock)(BOOL succeed, id _Nullable response);
                   
                   [invocation getArgument:&completionBlock atIndex:2];
                   // we mock server response here!
                   NSDictionary *d = @{t4.uniqueId:@{@"text": @"M4", @"isCompleted": @NO, @"priority": t4.priority},
                                       t3.uniqueId:@{@"text": @"M3", @"isCompleted": @NO, @"priority": t3.priority},
                                       t2.uniqueId:@{@"text": @"M2", @"isCompleted": @NO, @"priority": t2.priority},
                                       t1.uniqueId:@{@"text": @"M1", @"isCompleted": @NO, @"priority": t1.priority}};
                   
                   completionBlock(YES, d);
                   
               }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
               [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
               
               [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
               
                   [mockedAPI stopMocking];
                   
                   //---THEN---//
                   // we should have [M4, M3, 2, 1]
                   [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                      
                       NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"M4"], @"Failed");
                       NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"M3"], @"Failed");
                       NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"2"], @"Failed");
                       NSAssert([[(MDToDoObject*)results[3] text] isEqualToString:@"M1"], @"Failed");
                       
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
 this is very important one. what happens when there are conflicts of prios, when a todo is dirty?
 */
-(void)testGetToDosWithSameTextButDifferentPrios
{
    XCTestExpectation * e = [self expectationWithDescription:@"testGetToDosWithSameTextButDifferentPrios"];
    
    // we have on local these todos: [4(clean, 4), 3(clean, 3), 2(dirty, 2), 1(clean, 1)]
    // then we've got todos from server: [4(5), 3(4), 2(2.5), 1(2)]
    // the merge result should be [4(5), 3(4), 2(3), 1(2)]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"2", @"3", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            MDToDoObject *t4 = (MDToDoObject*)results[0];
            t4.priority = @(4.0);
            t4.isDirty = @NO;
            MDToDoObject *t3 = (MDToDoObject*)results[1];
            t3.priority = @(3.0);
            t3.isDirty = @NO;
            MDToDoObject *t2 = (MDToDoObject*)results[2];
            t2.priority = @(2.0);
            t2.isDirty = @YES;
            MDToDoObject *t1 = (MDToDoObject*)results[3];
            t1.priority = @(1.0);
            t1.isDirty = @NO;
            
            [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
                // now we have [4(clean, 4), 3(clean, 3), 2(dirty, 2), 1(clean, 1)] in local DB
                
                //--- WHEN ---//
                // we've got server response: [4(5), 3(4), 2(2.5), 1(2)]
                // we need to mock
                MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
                id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
                [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                    void (^completionBlock)(BOOL succeed, id _Nullable response);
                    
                    [invocation getArgument:&completionBlock atIndex:2];
                    // we mock server response here!
                    NSDictionary *d = @{t4.uniqueId:@{@"text": @"4", @"isCompleted": @NO, @"priority": @(5)},
                                        t3.uniqueId:@{@"text": @"3", @"isCompleted": @NO, @"priority": @(4)},
                                        t2.uniqueId:@{@"text": @"2", @"isCompleted": @NO, @"priority": @(2.5)},
                                        t1.uniqueId:@{@"text": @"1", @"isCompleted": @NO, @"priority": @(2)}};
                    
                    completionBlock(YES, d);
                    
                }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
                [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
                
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    
                    [mockedAPI stopMocking];
                    
                    //---THEN---//
                    // we should have [4(5), 3(4), 2(3), 1(2)]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                        NSAssert([(MDToDoObject*)results[0] priority].floatValue == 5, @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"3"], @"Failed");
                        NSAssert([(MDToDoObject*)results[1] priority].floatValue == 4, @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([(MDToDoObject*)results[2] priority].floatValue == 3, @"Failed");
                        NSAssert([[(MDToDoObject*)results[3] text] isEqualToString:@"1"], @"Failed");
                        NSAssert([(MDToDoObject*)results[3] priority].floatValue == 2, @"Failed");
                        
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
 some todos are dirty and order of todos from server is different from one from local DB
 */
-(void)testConflictScenario1
{
    XCTestExpectation * e = [self expectationWithDescription:@"ConflictScenario1"];
    
    // we have on local these todos: [4(clean, 4), 2(dirty, 3), 3(dirty, 2), 1(clean, 1)]
    // then we've got todos from server: [4(5), 3(4), 2(2.5), 1(2)]
    // the merge result should be [4(5), 2(4.25), 3(3.5), 1(2)]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"3", @"2", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            MDToDoObject *t4 = (MDToDoObject*)results[0];
            t4.priority = @(4.0);
            t4.isDirty = @NO;
            MDToDoObject *t3 = (MDToDoObject*)results[1];
            t3.priority = @(3.0);
            t3.isDirty = @YES;
            MDToDoObject *t2 = (MDToDoObject*)results[2];
            t2.priority = @(2.0);
            t2.isDirty = @YES;
            MDToDoObject *t1 = (MDToDoObject*)results[3];
            t1.priority = @(1.0);
            t1.isDirty = @NO;
            
            [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
                // now we have [4(clean, 4), 2(dirty, 3), 3(dirty, 2), 1(clean, 1)] in local DB
                
                //--- WHEN ---//
                // we've got server response: [4(5), 3(4), 2(2.5), 1(2)]
                // we need to mock
                MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
                id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
                [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                    void (^completionBlock)(BOOL succeed, id _Nullable response);
                    
                    [invocation getArgument:&completionBlock atIndex:2];
                    // we mock server response here!
                    NSDictionary *d = @{t4.uniqueId:@{@"text": @"4", @"isCompleted": @NO, @"priority": @(5)},
                                        t3.uniqueId:@{@"text": @"3", @"isCompleted": @NO, @"priority": @(4)},
                                        t2.uniqueId:@{@"text": @"2", @"isCompleted": @NO, @"priority": @(2.5)},
                                        t1.uniqueId:@{@"text": @"1", @"isCompleted": @NO, @"priority": @(2)}};
                    
                    completionBlock(YES, d);
                    
                }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
                [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
                
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    
                    [mockedAPI stopMocking];
                    
                    //---THEN---//
                    // we should have [4(5), 2(4.25), 3(3.5), 1(2)]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                        NSAssert([(MDToDoObject*)results[0] priority].floatValue == 5, @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([(MDToDoObject*)results[1] priority].floatValue == 4.25, @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"3"], @"Failed");
                        NSAssert([(MDToDoObject*)results[2] priority].floatValue == 3.5, @"Failed");
                        NSAssert([[(MDToDoObject*)results[3] text] isEqualToString:@"1"], @"Failed");
                        NSAssert([(MDToDoObject*)results[3] priority].floatValue == 2, @"Failed");
                        
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
 what happens when todo's done state is changed, when it is dirty?
 */
-(void)testConflictScenario2
{
    XCTestExpectation * e = [self expectationWithDescription:@"ConflictScenario2"];
    
    // we have on local these todos: [4(dirty, done), 2(clean, open), 3(clean, open), 1(clean, open)]
    // then we've got todos from server: [4(open), 3(open), 2(open), 1(open)]
    // the merge result should be [4(done), 3(open), 2(open), 1(open)]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"3", @"2", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            MDToDoObject *t4 = (MDToDoObject*)results[0];
            t4.priority = @(4.0);
            t4.isDirty = @YES;
            t4.isCompleted = @YES;
            MDToDoObject *t3 = (MDToDoObject*)results[1];
            t3.priority = @(3.0);
            t3.isDirty = @NO;
            t3.isCompleted = @NO;
            MDToDoObject *t2 = (MDToDoObject*)results[2];
            t2.priority = @(2.0);
            t2.isDirty = @NO;
            t2.isCompleted = @NO;
            MDToDoObject *t1 = (MDToDoObject*)results[3];
            t1.priority = @(1.0);
            t1.isDirty = @NO;
            
            [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
                // now we have [4(dirty, done), 2(clean, open), 3(clean, open), 1(clean, open)] in local DB
                
                //--- WHEN ---//
                // we've got server response:  [4(open), 3(open), 2(open), 1(open)]
                // we need to mock
                MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
                id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
                [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                    void (^completionBlock)(BOOL succeed, id _Nullable response);
                    
                    [invocation getArgument:&completionBlock atIndex:2];
                    // we mock server response here!
                    NSDictionary *d = @{t4.uniqueId:@{@"text": @"4", @"isCompleted": @NO, @"priority": @(5)},
                                        t3.uniqueId:@{@"text": @"3", @"isCompleted": @NO, @"priority": @(4)},
                                        t2.uniqueId:@{@"text": @"2", @"isCompleted": @NO, @"priority": @(3)},
                                        t1.uniqueId:@{@"text": @"1", @"isCompleted": @NO, @"priority": @(2)}};
                    
                    completionBlock(YES, d);
                    
                }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
                [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
                
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    
                    [mockedAPI stopMocking];
                    
                    //---THEN---//
                    // we should have [3(open), 2(open), 1(open)]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"], @"Failed");
                        NSAssert([(MDToDoObject*)results[0] isCompleted].boolValue == NO, @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([(MDToDoObject*)results[1] isCompleted].boolValue == NO, @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
                        NSAssert([(MDToDoObject*)results[2] isCompleted].boolValue == NO, @"Failed");
                        
                        // we should have [4(done)]
                        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeDone completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                            
                            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                            NSAssert([(MDToDoObject*)results[0] isCompleted].boolValue == YES, @"Failed");
                            
                             [e fulfill];
                            
                        }];
                        
                       
                    }];
                }];
                
                
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];

}

/**
 what happens when todo's done state is changed (local open vs. server done), when it is dirty?
 */
-(void)testConflictScenario3
{
    XCTestExpectation * e = [self expectationWithDescription:@"ConflictScenario3"];
    
    // we have on local these todos: [4(dirty, open), 2(clean, open), 3(clean, open), 1(clean, open)]
    // then we've got todos from server: [4(done), 3(open), 2(open), 1(open)]
    // the merge result should be [4(open), 3(open), 2(open), 1(open)]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"3", @"2", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            MDToDoObject *t4 = (MDToDoObject*)results[0];
            t4.priority = @(4.0);
            t4.isDirty = @YES;
            t4.isCompleted = @NO;
            MDToDoObject *t3 = (MDToDoObject*)results[1];
            t3.priority = @(3.0);
            t3.isDirty = @NO;
            t3.isCompleted = @NO;
            MDToDoObject *t2 = (MDToDoObject*)results[2];
            t2.priority = @(2.0);
            t2.isDirty = @NO;
            t2.isCompleted = @NO;
            MDToDoObject *t1 = (MDToDoObject*)results[3];
            t1.priority = @(1.0);
            t1.isDirty = @NO;
            
            [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
                // now we have [4(dirty, open), 2(clean, open), 3(clean, open), 1(clean, open)] in local DB
                
                //--- WHEN ---//
                // we've got server response:  [4(done), 3(open), 2(open), 1(open)]
                // we need to mock
                MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
                id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
                [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                    void (^completionBlock)(BOOL succeed, id _Nullable response);
                    
                    [invocation getArgument:&completionBlock atIndex:2];
                    // we mock server response here!
                    NSDictionary *d = @{t4.uniqueId:@{@"text": @"4", @"isCompleted": @YES, @"priority": @(5)},
                                        t3.uniqueId:@{@"text": @"3", @"isCompleted": @NO, @"priority": @(4)},
                                        t2.uniqueId:@{@"text": @"2", @"isCompleted": @NO, @"priority": @(3)},
                                        t1.uniqueId:@{@"text": @"1", @"isCompleted": @NO, @"priority": @(2)}};
                    
                    completionBlock(YES, d);
                    
                }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
                [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
                
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    
                    [mockedAPI stopMocking];
                    
                    //---THEN---//
                    // we should have [4(open), 3(open), 2(open), 1(open)]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                        NSAssert([(MDToDoObject*)results[0] isCompleted].boolValue == NO, @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"3"], @"Failed");
                        NSAssert([(MDToDoObject*)results[1] isCompleted].boolValue == NO, @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([(MDToDoObject*)results[2] isCompleted].boolValue == NO, @"Failed");
                        NSAssert([[(MDToDoObject*)results[3] text] isEqualToString:@"1"], @"Failed");
                        NSAssert([(MDToDoObject*)results[3] isCompleted].boolValue == NO, @"Failed");
                        
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
 some complex conflicts
 */
-(void)testConflictScenario4
{
    XCTestExpectation * e = [self expectationWithDescription:@"ConflictScenario4"];
    
    // we have on local these todos: [4(dirty, done), 2(dirty, open), 3(clean, open), 1(clean, open)]
    // then we've got todos from server: [4(open), 3(open), 2(done), 1(open)]
    // the merge result should be [4(done)], [2(open), 3(open), 1(open)]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"3", @"2", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            MDToDoObject *t4 = (MDToDoObject*)results[0];
            t4.priority = @(4.0);
            t4.isDirty = @YES;
            t4.isCompleted = @YES;
            MDToDoObject *t3 = (MDToDoObject*)results[1];
            t3.priority = @(3.0);
            t3.isDirty = @YES;
            t3.isCompleted = @NO;
            MDToDoObject *t2 = (MDToDoObject*)results[2];
            t2.priority = @(2.0);
            t2.isDirty = @NO;
            t2.isCompleted = @NO;
            MDToDoObject *t1 = (MDToDoObject*)results[3];
            t1.priority = @(1.0);
            t1.isDirty = @NO;
            t1.isCompleted = @NO;
            
            [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
                // now we have [4(dirty, done), 2(dirty, open), 3(clean, open), 1(clean, open)] in local DB
                
                //--- WHEN ---//
                // we've got server response:  [4(open), 3(open), 2(done), 1(open)]
                // we need to mock
                MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
                id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
                [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                    void (^completionBlock)(BOOL succeed, id _Nullable response);
                    
                    [invocation getArgument:&completionBlock atIndex:2];
                    // we mock server response here!
                    NSDictionary *d = @{t4.uniqueId:@{@"text": @"4", @"isCompleted": @NO, @"priority": @(5)},
                                        t2.uniqueId:@{@"text": @"3", @"isCompleted": @NO, @"priority": @(4)},
                                        t3.uniqueId:@{@"text": @"2", @"isCompleted": @YES, @"priority": @(3)},
                                        t1.uniqueId:@{@"text": @"1", @"isCompleted": @NO, @"priority": @(2)}};
                    
                    completionBlock(YES, d);
                    
                }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
                [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
                
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    
                    [mockedAPI stopMocking];
                    
                    //---THEN---//
                    // we should have [2(open), 3(open), 1(open)]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"3"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
                        
                        
                        // we should have [4(done)]
                        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeDone completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                            
                            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                            
                            [e fulfill];
                            
                        }];
                        
                        
                    }];
                }];
                
                
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];
 
}

/**
 some complex conflicts
 */
-(void)testConflictScenario5
{
    XCTestExpectation * e = [self expectationWithDescription:@"ConflictScenario5"];
    
    // we have on local these todos: [4(dirty, open), 2(dirty, open), 3(clean, open), 1(clean, open)]
    // then we've got todos from server: [4(done), 3(done), 2(done), 1(open)]
    // the merge result should be [4(open), 2(open), 1(open)], [3(done)]
    
    //--- GIVEN ---//
    [self clearAllToDos];
    [self createDummyToDosWithTexts:@[@"1", @"3", @"2", @"4"] completionBlock:^{
        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
            
            MDToDoObject *t4 = (MDToDoObject*)results[0];
            t4.priority = @(4.0);
            t4.isDirty = @YES;
            t4.isCompleted = @NO;
            MDToDoObject *t3 = (MDToDoObject*)results[1];
            t3.priority = @(3.0);
            t3.isDirty = @YES;
            t3.isCompleted = @NO;
            MDToDoObject *t2 = (MDToDoObject*)results[2];
            t2.priority = @(2.0);
            t2.isDirty = @NO;
            t2.isCompleted = @NO;
            MDToDoObject *t1 = (MDToDoObject*)results[3];
            t1.priority = @(1.0);
            t1.isDirty = @NO;
            t1.isCompleted = @NO;
            
            [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
                // now we have [4(dirty, open), 2(dirty, open), 3(clean, open), 1(clean, open)] in local DB
                
                //--- WHEN ---//
                // we've got server response:  [4(done), 3(done), 2(done), 1(open)]
                // we need to mock
                MDDataCloudAPI *cloudAPI = [MDDataCloudAPI sharedInstance];
                id mockedAPI = [OCMockObject partialMockForObject:cloudAPI];
                [[[mockedAPI stub] andDo:^(NSInvocation *invocation) {
                    void (^completionBlock)(BOOL succeed, id _Nullable response);
                    
                    [invocation getArgument:&completionBlock atIndex:2];
                    // we mock server response here!
                    NSDictionary *d = @{t4.uniqueId:@{@"text": @"4", @"isCompleted": @YES, @"priority": @(5)},
                                        t2.uniqueId:@{@"text": @"3", @"isCompleted": @YES, @"priority": @(4)},
                                        t3.uniqueId:@{@"text": @"2", @"isCompleted": @YES, @"priority": @(3)},
                                        t1.uniqueId:@{@"text": @"1", @"isCompleted": @NO, @"priority": @(2)}};
                    
                    completionBlock(YES, d);
                    
                }] getAllToDosInJSONFromServerWithComplectionBlock:OCMOCK_ANY];
                [[[mockedAPI stub] andReturn:mockedAPI] sharedInstance];
                
                [[MDUserManager sharedInstance] getAndMergeLastToDoStateFromServerWithComplectionBlock:^(BOOL succeed) {
                    
                    [mockedAPI stopMocking];
                    
                    //---THEN---//
                    // we should have [4(open), 2(open), 1(open)]
                    [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeToDo completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                        
                        NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"4"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[1] text] isEqualToString:@"2"], @"Failed");
                        NSAssert([[(MDToDoObject*)results[2] text] isEqualToString:@"1"], @"Failed");
                        
                        
                        // we should have [3(done)]
                        [[MDUserManager sharedInstance] fetchTodosForListType:MDActiveListTypeDone completionBlock:^(BOOL succeed, NSArray<MDToDoObject *> * _Nullable results) {
                            
                            NSAssert([[(MDToDoObject*)results[0] text] isEqualToString:@"3"], @"Failed");
                            
                            [e fulfill];
                            
                        }];
                        
                        
                    }];
                }];
                
                
            }];
        }];
    }];
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        
    }];

}




@end
