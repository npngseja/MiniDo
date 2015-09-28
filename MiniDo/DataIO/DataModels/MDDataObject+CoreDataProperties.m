//
//  MDDataObject+CoreDataProperties.m
//  MiniDo
//
//  Created by npngseja on 28/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDDataObject+CoreDataProperties.h"

@implementation MDDataObject (CoreDataProperties)

@dynamic createdAt;
@dynamic isDirty;
@dynamic uniqueId;
@dynamic updatedAt;
@dynamic isRemoved;

@end
