//
//  MDDataCloudAPI.h
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

//
//  This class is a kind of mock to demonstrate cloud sync handling
//

#import <Foundation/Foundation.h>
#import "MDToDoObject.h"

@interface MDDataCloudAPI : NSObject

/**
 return singleton instance
 
 @return shared instance
 */
+ (nonnull instancetype)sharedInstance;

/**
 GET all todos from server. if successful, then it will also modify localDB. Your first source to get latest tods are MDDataLocalIO
 */
-(void)getAllToDosFromServerWithComplectionBlock:(nonnull void (^)(BOOL succeed, NSError * _Nullable error))completionBlock;
/**
 POST(store) dirty data onto server
 */
-(void)postDataArray:(nonnull NSArray<MDDataObject*>*)array ontoServerWithCompletionBlock:(nonnull void (^)(BOOL succeed, NSError * _Nullable error))completionBlock;

@end
