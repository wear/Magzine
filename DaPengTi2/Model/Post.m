//
//  Post.m
//  DaPengTi2
//
//  Created by  on 12-6-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "Post.h"

@implementation Post
@synthesize title = _title;
@synthesize content = _content;
@synthesize postId = _postId;

+(NSArray*)postsFromJSONDate:(NSData *)responseData{
    NSError* error;
    NSMutableArray *posts = [[NSMutableArray alloc] init];

    NSArray* postsJson = [NSJSONSerialization 
                          JSONObjectWithData:responseData //1
                          options:kNilOptions 
                          error:&error];

    for (int i=0; i<[postsJson count]; i++) {
        id postJson = [postsJson objectAtIndex:i];
        Post *post = [self initPostDictionaryInfo:(NSDictionary*)postJson];
        [posts addObject:post];
    }
    return posts;
}

+(Post*)initPostDictionaryInfo:(NSDictionary*)postInfo{
    Post *post = [[Post alloc] init];
    post.title = [postInfo valueForKey:@"title"];
    post.content = [postInfo valueForKey:@"content"];
    post.postId = [postInfo valueForKey:@"post_id"];
    return post;
}

@end
