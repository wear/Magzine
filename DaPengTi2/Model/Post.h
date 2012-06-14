//
//  Post.h
//  DaPengTi2
//
//  Created by  on 12-6-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Post : NSObject
@property(strong,nonatomic) NSString *title;
@property(strong,nonatomic) NSString *content;
@property(strong,nonatomic) NSNumber *postId;

+(NSArray*)postsFromJSONDate:(NSData *)responseData;
@end
