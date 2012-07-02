//
//  Issue+Rss.m
//  DaPengTi2
//
//  Created by  on 12-6-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Issue+Rss.h"

@implementation Issue (Rss)
+ (Issue*)issueFromRssFeed:(NSDictionary *)RssFeed inManagedObjectContext:(NSManagedObjectContext *)context{
    Issue *issue = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Issue"];
    request.predicate = [NSPredicate predicateWithFormat:@"title = %@", [RssFeed valueForKey:@"title"]];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];	
    
    
    if (!matches || ([matches count] > 1)) {
        // handle error
    } else if (![matches count]) {
        issue = [NSEntityDescription insertNewObjectForEntityForName:@"Issue"
                                             inManagedObjectContext:context];
        issue.title = [RssFeed valueForKey:@"title"];
        issue.note = [RssFeed valueForKey:@"note"];
        issue.issueID = [RssFeed valueForKey:@"issue_id"];
    } else {
        issue = [matches lastObject];
    }
    
    return issue;
}
@end
