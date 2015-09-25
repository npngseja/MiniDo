//
//  MDDataIO.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDDataIO.h"

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

- (void)saveInBackgroundWithCompletionBlock:(void (^)(BOOL))completionBlock {
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
    [self.managedObjectContext deleteObject:o];
    
    if (completionBlock) {
        completionBlock();
    }
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
