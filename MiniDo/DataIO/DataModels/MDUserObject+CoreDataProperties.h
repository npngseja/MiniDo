//
//  MDUserObject+CoreDataProperties.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDUserObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDUserObject (CoreDataProperties)

@property (nullable, nonatomic, retain) NSOrderedSet<MDToDoObject *> *todoList;

@end

@interface MDUserObject (CoreDataGeneratedAccessors)

- (void)insertObject:(MDToDoObject *)value inTodoListAtIndex:(NSUInteger)idx;
- (void)removeObjectFromTodoListAtIndex:(NSUInteger)idx;
- (void)insertTodoList:(NSArray<MDToDoObject *> *)value atIndexes:(NSIndexSet *)indexes;
- (void)removeTodoListAtIndexes:(NSIndexSet *)indexes;
- (void)replaceObjectInTodoListAtIndex:(NSUInteger)idx withObject:(MDToDoObject *)value;
- (void)replaceTodoListAtIndexes:(NSIndexSet *)indexes withTodoList:(NSArray<MDToDoObject *> *)values;
- (void)addTodoListObject:(MDToDoObject *)value;
- (void)removeTodoListObject:(MDToDoObject *)value;
- (void)addTodoList:(NSOrderedSet<MDToDoObject *> *)values;
- (void)removeTodoList:(NSOrderedSet<MDToDoObject *> *)values;

@end

NS_ASSUME_NONNULL_END
