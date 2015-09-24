//
//  MDAppControl.h
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDMiniDoConstants.h"

@class MDBaseViewController;

@interface MDAppControl : NSObject

@property (readonly, weak) MDBaseViewController *baseVc;

/**
 currently visible list type
 */
@property MDActiveListType activeListType;

/**
 return singleton instance
 
 @return shared instance
 */
+ (nonnull instancetype)sharedInstance;

/**
 application launch sequence
 */
- (void)doAppLaunchSequenceWithCompletionBlock:(nullable void (^)())completionBlock;

/**
 will change app layout for the target active list type
 */
- (void)setActiveListType:(MDActiveListType)activeListType
                 animated:(BOOL)animated
          completionBlock:(nullable void (^)())completionBlock;

@end
