//
//  DaPengTi2ViewController.h
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PostView;
@class Post;

@interface DaPengTi2ViewController : UIViewController 
@property (weak, nonatomic) IBOutlet PostView *postView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;
@property (nonatomic, strong) UIBarButtonItem *splitViewBarButtonItem;
@property(strong,nonatomic) Post* post;
-(void)updatePostViewForPost:(Post*)post;
@end
