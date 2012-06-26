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
@property (strong, nonatomic) NSMutableArray* columns;
@property(strong,nonatomic) NSArray* images;
@property(assign) NSUInteger index;
@property(strong,nonatomic) NSMutableArray* firstPageContent;

-(void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs;
-(void)displayTiledPost:(Post*)post;
@end
