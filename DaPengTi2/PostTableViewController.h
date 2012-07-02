//
//  PostTableViewController.h
//  DaPengTi2
//
//  Created by  on 12-6-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Issue;


@interface PostTableViewController : UITableViewController 
@property(strong,nonatomic) Issue* issue;
@end
