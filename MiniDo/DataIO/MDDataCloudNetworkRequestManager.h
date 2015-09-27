//
//  MDDataCloudNetworkRequestManager.h
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

//  NOTE: THIS CLASS DOES NOT HAVE ACTUAL IMPLEMENTATION!
//
//  NSURLConnection is quite old class to make a http request, so it is preferred to use NSURLSession
//  or AFNetworking framework instead. Still, I give here just interface to make several http requests
//  simultaneously and get correct responses for each requests.
//
//  Cancelling running connection is also very important to save network resources. This class shows
//  how to manage cancelled connection.
//
//  But NSURLSession or AFNetworking do those stuff much better....

#import <Foundation/Foundation.h>
#import "MDURLConnection.h"

@interface MDDataCloudNetworkRequestManager : NSObject <NSURLConnectionDelegate>

/**
 attempt to make an API call and return its response in completion block
 @param path
        api call path without root url. root url will be attached in the method
 @return NSURLConnection instance, which is attempting to make a connection
 */
-(nullable MDURLConnection*)requestAPICallWithPath:(nonnull NSString*)path
              completionBlock:(nullable void (^)(BOOL succeed, id _Nullable response))completionBlock;

/**
 cancel given connection
 */
-(void)cancelConnection:(nonnull MDURLConnection*)connection;


@end
