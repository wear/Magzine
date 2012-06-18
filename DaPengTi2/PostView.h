//
//  PostView.h
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Post;
@interface PostView : UIScrollView<UIScrollViewDelegate>
@property(strong, nonatomic) NSAttributedString* attString;
@property (strong, nonatomic) NSMutableArray* frames;
@property(strong,nonatomic) NSArray* images;
@property (assign) NSUInteger index;

-(void)buildFrames;
-(void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs;
-(void)displayTiledPost:(Post*)post;
@end
