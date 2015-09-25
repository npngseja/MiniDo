//
//  MiniDoTests.m
//  MiniDoTests
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

/*
 - add new todo: when new todo is added, user's todoCount and count of fetched todos should be same user's todos should have one more todo object.
 - remove a todo: todo should be removed. be careful of todoCount!
 */

#import <XCTest/XCTest.h>

@interface MiniDoTests : XCTestCase

@end

@implementation MiniDoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testAddNewToDo {
   
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
