//
//  MDDataObject+CoreDataProperties.h
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "MDDataObject.h"

NS_ASSUME_NONNULL_BEGIN

@interface MDDataObject (CoreDataProperties)

@property (nullable, nonatomic, retain) NSDate *createdAt;
@property (nullable, nonatomic, retain) NSNumber *isDirty;
@property (nullable, nonatomic, retain) NSString *uniqueId;
@property (nullable, nonatomic, retain) NSDate *updatedAt;

@end

NS_ASSUME_NONNULL_END
