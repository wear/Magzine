//
//  Picture+feed.m
//  DaPengTi2
//
//  Created by  on 12-7-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Picture+feed.h"

@implementation Picture (feed)
+ (Picture *)pictureFromFeed:(NSDictionary *)feed inManagedObjectContext:(NSManagedObjectContext *)context{
    Picture *picture = nil;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Picture"];
    request.predicate = [NSPredicate predicateWithFormat:@"pictureID = %@", [feed valueForKey:@"pciture_id"]];
    
    NSError *error = nil;
    NSArray *matches = [context executeFetchRequest:request error:&error];	
    
    if (!matches || ([matches count] > 1)) {
        // handle error
    } else if (![matches count]) {
        picture = [NSEntityDescription insertNewObjectForEntityForName:@"Picture"
                                             inManagedObjectContext:context];
        picture.url = [feed valueForKey:@"url"];
        picture.pictureID = [feed valueForKey:@"picture_id"];
        picture.width = [feed valueForKey:@"width"];
        picture.height  = [feed valueForKey:@"height"];
        picture.identifier = [feed valueForKey:@"identifier"];
    } else {
        picture = [matches lastObject];
    }
    
    return picture;
}
@end
