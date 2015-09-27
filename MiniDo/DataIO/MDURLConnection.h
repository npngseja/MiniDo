//
//  MDURLConnection.h
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

//
//  This class contains old technology to demonstrate completion handler with network response
//  It it not an actual implementation, but a kind of pseudo code!
//

#import <Foundation/Foundation.h>

@interface MDURLConnection : NSURLConnection

@property(nullable, nonatomic, strong) NSMutableData *data;
@property(nullable, nonatomic, copy) void (^completionBlock)(MDURLConnection * _Nullable con, NSData * _Nullable data, NSError * _Nullable error);

@end
