//
//  MDToDoObject+CoreDataProperties.h
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDToDoObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDToDoObject (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *completionDate;
@property (nullable, nonatomic, retain) NSDate *creationDate;
@property (nullable, nonatomic, retain) NSNumber *isCompleted;
@property (nullable, nonatomic, retain) NSNumber *priority;
@property (nullable, nonatomic, retain) NSString *text;
@property (nullable, nonatomic, retain) MDUserObject *owner;

@end

NS_ASSUME_NONNULL_END
