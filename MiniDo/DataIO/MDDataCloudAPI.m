//
//  MDDataCloudAPI.m
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDDataCloudAPI.h"
#import "MDDataCloudNetworkRequestManager.h"
#import "MDDataIO.h"

// this import is only for returning dummy todos
#import "MDUserManager.h"

@implementation MDDataCloudAPI
{
    MDDataCloudNetworkRequestManager *__networkRequestManager;
    MDURLConnection *__lastPostAPICall;    // hook last post call to cancel it if necessary
    MDURLConnection *__lastGetAPICall;      // hook last get call to cancel it if necessary
}

+ (instancetype)sharedInstance
{
    static MDDataCloudAPI *_instance = nil;
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
        __networkRequestManager = [[MDDataCloudNetworkRequestManager alloc] init];
    }
    
    return self;
}

#warning ACTUAL NETWORK SYNC IS MISSING.
-(void)getAllToDosFromServerWithComplectionBlock:(void (^)(BOOL, NSError * _Nullable))completionBlock
{
    
    [self getAllToDosInJSONFromServerWithComplectionBlock:^(BOOL succeed, id response) {
        //TODO: merging conflicts!!!. prios can be very different!
        
        
        // return always YES
        if (completionBlock) {
            completionBlock(YES, nil);
        }
    }];
    
    
}

/**
 return todos from current local DB. Since we do not have server, we pretend to have a response from server with ones from local DB. the return format is array of dictionary like parsed json object
 */
-(void)getAllToDosInJSONFromServerWithComplectionBlock:(void (^)(BOOL succeed, id response))completionBlock
{
    // cancel last running post api call, when it is available.
    // this is important for an efficient usage of device's network resources.
    [__networkRequestManager cancelConnection:__lastGetAPICall];
    
    // make a new connection to post data
    MDURLConnection *con = [__networkRequestManager requestAPICallWithPath:@"..." completionBlock:^(BOOL succeed, id  _Nullable response) {
        
    }];
    
    __lastGetAPICall = con;
    
    //
    // Assume that GET call is successful.
    // We provide current local DB in JSON protocol only for Testing!!
    __lastGetAPICall = nil;
    
    [[MDDataIO sharedInstance] fetchObjectWithClassName:NSStringFromClass([MDToDoObject class])
                                              predicate:[NSPredicate predicateWithFormat:@"(%K == %@)", @"owner", [MDUserManager sharedInstance].currentUser]
                                        sortDescriptors:nil
                                        completionBlock:^(NSArray<MDDataObject *> * _Nullable results, NSError * _Nullable error) {
                                            
                                            NSMutableArray *a = [@[] mutableCopy];
                                            // we have all todos for current user
                                            for (MDToDoObject *t in results) {
                                                NSDictionary *d = @{@"uniqueId": t.uniqueId,
                                                                    @"isCompleted": t.isCompleted,
                                                                    @"text": t.text};
                                                [a addObject:d];
                                            }
                                            
                                            // we return response in JSON protocol, which is
                                            // built with todos in local DB, for a testing purpose!
                                            if (completionBlock) {
                                                completionBlock(YES, a);
                                            }
        
    }];
}

#warning ACTUAL NETWORK SYNC IS MISSING.
-(void)postDataArray:(nonnull NSArray<MDDataObject*>*)array ontoServerWithCompletionBlock:(nonnull void (^)(BOOL succeed, NSError * _Nullable error))completionBlock
{
    // cancel last running post api call, when it is available.
    // this is important for an efficient usage of device's network resources.
    [__networkRequestManager cancelConnection:__lastPostAPICall];
    
    // make a new connection to post data
    MDURLConnection *con = [__networkRequestManager requestAPICallWithPath:@"..." completionBlock:^(BOOL succeed, id  _Nullable response) {
        
    }];
    
    __lastPostAPICall = con;
    
    
    //
    // Assume that POST call is successful. This is why the code below is OUT of the response block above.
    //
    
    __lastPostAPICall = nil;
    
    // set those todos clean.
    for (MDToDoObject *o in array) {
        o.isDirty = @(NO);
    }
    
    [[MDDataIO sharedInstance] saveLocalDBWithCompletionBlock:^(BOOL succeed) {
        if (completionBlock) {
            completionBlock(YES, nil);
        }
    }];
    
}

@end
