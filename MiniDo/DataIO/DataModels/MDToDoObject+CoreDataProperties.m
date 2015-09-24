//
//  MDToDoObject+CoreDataProperties.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDToDoObject+CoreDataProperties.h"

@implementation MDToDoObject (CoreDataProperties)

@dynamic isCompleted;
@dynamic text;
@dynamic completionDate;
@dynamic owner;

@end
