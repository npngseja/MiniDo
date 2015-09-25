//
//  MDDataIO.h
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

#pragma mark - CoreData Stack -
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic, nonnull) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic, nonnull) NSPersistentStoreCoordinator *persistentStoreCoordinator;

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
 save moc into the persistant store
 */
-(void)saveInBackgroundWithCompletionBlock:(nullable void (^)(BOOL succeed))completionBlock;

@end
