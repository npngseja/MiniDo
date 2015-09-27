//
//  MDDataCloudNetworkRequestManager.m
//  MiniDo
//
//  Created by npngseja on 27/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDDataCloudNetworkRequestManager.h"
#define API_ROOT_URL @"https://api.minido.com"  // of course, this does not exists! :p

@implementation MDDataCloudNetworkRequestManager

-(MDURLConnection*)requestAPICallWithPath:(NSString *)path completionBlock:(void (^)(BOOL, id _Nullable))completionBlock
{
    NSURL *rootUrl = [NSURL URLWithString:API_ROOT_URL];
    NSURL *finalAPIUrl = [rootUrl URLByAppendingPathComponent:path];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:finalAPIUrl];
    
    // Create url connection and fire request
    // IGNORE the warning. This code is just a demonstration.
    // We already know that NSURLSession is preferred.
    MDURLConnection *conn = [[MDURLConnection alloc] initWithRequest:request delegate:self];
    conn.completionBlock = ^(MDURLConnection * _Nullable con, NSData * _Nullable data, NSError * _Nullable error) {
        
        if (completionBlock) {
            completionBlock(error == nil ? YES : NO, data);
        }
    };

    return conn;
}

-(void)cancelConnection:(MDURLConnection *)connection
{
    [connection cancel];
    
    // [NSURLConnection cancel] does not make any delegate method(!?!)
    // We have to improve error object...
    connection.completionBlock(connection, nil, [NSError errorWithDomain:NSCocoaErrorDomain code:-1 userInfo:nil]);
}

#pragma mark - NSURLConnection Delegate -
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    ((MDURLConnection*)connection).data = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [((MDURLConnection*)connection).data appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    MDURLConnection *c = (MDURLConnection*)connection;
    c.completionBlock(c, c.data, nil);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    MDURLConnection *c = (MDURLConnection*)connection;
    c.completionBlock(c, nil, error);
}
@end
