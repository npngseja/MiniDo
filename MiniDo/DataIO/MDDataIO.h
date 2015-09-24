//
//  MDDataIO.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface MDDataIO : NSObject

/**
 return singleton instance
 
 @return shared instance
 */
+ (instancetype)sharedInstance;

#pragma mark - CoreData Stack -
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

-(void)saveInBackgroundWithCompletionBlock:(void (^)(BOOL succeed))completionBlock;

@end
