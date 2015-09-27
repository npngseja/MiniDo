//
//  MDDataLocalIO.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MDDataObject.h"

@interface MDDataIO : NSObject

/**
 return singleton instance
 
 @return shared instance
 */
+ (nonnull instancetype)sharedInstance;

/**
 fetch objects with class and predicate
 @param className
        data object class name
 @param predicate
        NSPredicate object. can be nil.
 */
-(void)fetchObjectWithClassName:(nonnull NSString*)className
                      predicate:(nullable NSPredicate*)p
                 sortDescriptors:(nullable NSArray<NSSortDescriptor*>*)s
                completionBlock:(nonnull void (^)(NSArray<MDDataObject*> * _Nullable results, NSError * _Nullable error))completionBlock;

/**
 create a data object and return. the object is not persist yet!
 @param className
        class name that you want to create.
 */
-(void)createObjectWithClassName:(nonnull NSString*)className
                 completionBlock:(nonnull void (^)(BOOL succeed, MDDataObject * _Nullable object))completionBlock;

/**
 delete a data object
 */
-(void)deleteObject:(nonnull MDDataObject *)o
    completionBlock:(nullable void (^)())completionBlock;

/**
 sync over cloud. this will fetch all dirty todos and store them on cloud. after sync those todos will be set as clean
 */
-(void)storeCurrentStateOnCloudWithComplectionBlock:(nullable void (^)(BOOL succeed))completionBlock;

/**
 sync from cloud. get all todos for the user and update local DB. merging cloud and local DBs will be done after API response in MDDataCloudAPI.
 */
-(void)retrieveLastStateFromCloudWithCompletionBlock:(nullable void (^)(BOOL succeed))completionBlock;

/**
 save moc into the persistant store
 */
-(void)saveLocalDBWithCompletionBlock:(nullable void (^)(BOOL succeed))completionBlock;

#pragma mark - CoreData Stack -
/**
 this context is not readonly, in order to unit test code is able to inject in-memory-store-based-context
 */
@property (strong, nonatomic, nonnull) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic, nonnull) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
