//
//  MDToDoObject+CoreDataProperties.m
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDToDoObject+CoreDataProperties.h"

@implementation MDToDoObject (CoreDataProperties)

@dynamic completionDate;
@dynamic creationDate;
@dynamic isCompleted;
@dynamic priority;
@dynamic text;
@dynamic owner;

@end
