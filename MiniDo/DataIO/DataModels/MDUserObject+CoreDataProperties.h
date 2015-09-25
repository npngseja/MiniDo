//
//  MDUserObject+CoreDataProperties.h
//  MiniDo
//
//  Created by npngseja on 25/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDUserObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDUserObject (CoreDataProperties)

@property (nullable, nonatomic, retain) NSNumber *todoCount;
@property (nullable, nonatomic, retain) NSNumber *doneCount;
@property (nullable, nonatomic, retain) NSSet<MDToDoObject *> *todos;

@end

@interface MDUserObject (CoreDataGeneratedAccessors)

- (void)addTodosObject:(MDToDoObject *)value;
- (void)removeTodosObject:(MDToDoObject *)value;
- (void)addTodos:(NSSet<MDToDoObject *> *)values;
- (void)removeTodos:(NSSet<MDToDoObject *> *)values;

@end

NS_ASSUME_NONNULL_END
