//
//  MDUserManager.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MDUserObject.h"
#import "MDToDoObject.h"
@interface MDUserManager : NSObject

/**
 return singleton instance
 
 @return shared instance
 */
+ (nonnull instancetype)sharedInstance;

/**
 fetch last logged in user. If nothing exists, create new one. Then make an attempt to log in on server (pretend it)
 If we want to have a real login function on cloud server, we need more complex login process.
 */
-(void)loginWithLastLoginUserWithCompletionBlock:(nullable void (^)(BOOL succeed, MDUserObject * __nonnull user))completionBlock;

@end
