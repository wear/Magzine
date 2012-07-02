//
//  Picture+feed.h
//  DaPengTi2
//
//  Created by  on 12-7-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Picture.h"

@interface Picture (feed)
+ (Picture *)pictureFromFeed:(NSDictionary *)feed inManagedObjectContext:(NSManagedObjectContext *)context;
@end
