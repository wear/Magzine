//
//  Post.h
//  DaPengTi2
//
//  Created by  on 12-7-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue;

@interface Post : NSManagedObject

@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSNumber * postID;
@property (nonatomic, retain) NSString * layout;
@property (nonatomic, retain) NSString * content;
@property (nonatomic, retain) NSNumber * unread;
@property (nonatomic, retain) Issue *issue;

@end
