//
//  Issue+list.h
//  DaPengTi2
//
//  Created by  on 12-7-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Issue.h"

@interface Issue (list)
+ (Issue*)issueFromRssFeed:(NSDictionary *)RssFeed inManagedObjectContext:(NSManagedObjectContext *)context;
+(NSArray*)allIssueInContext:(NSManagedObjectContext*)context;
@end
