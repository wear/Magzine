//
//  Post+feed.m
//  DaPengTi2
//
//  Created by  on 12-7-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Post+feed.h"


@implementation Post (feed)
+ (Post *)postsFromFeed:(NSDictionary *)feed inManagedObjectContext:(NSManagedObjectContext *)context{
    Post *post = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Post"];
    request.predicate = [NSPredicate predicateWithFormat:@"postID = %@", [feed valueForKey:@"post_id"]];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];	
    
    if (!matches || ([matches count] > 1)) {
        // handle error
    } else if (![matches count]) {
        post = [NSEntityDescription insertNewObjectForEntityForName:@"Post"
                                             inManagedObjectContext:context];
        post.title = [feed valueForKey:@"title"];
        post.postID = [feed valueForKey:@"post_id"];
        post.content = [feed valueForKey:@"content"];
        post.layout  = [feed valueForKey:@"layout"];
    } else {
        post = [matches lastObject];
    }
    
    return post;
}
@end
