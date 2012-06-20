//
//  PostTableViewController.m
//  DaPengTi2
//
//  Created by  on 12-6-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PostTableViewController.h"
#import "DaPengTi2ViewController.h"
#import "Post.h"
#import "PostCell.h"
#import "HTMLNode.h"
#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) 
#define kSearchURL @"http://localhost:3000" 

@interface PostTableViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property(strong,nonatomic) NSArray* posts;
@end

@implementation PostTableViewController
@synthesize indicator = _indicator;
@synthesize posts = _posts;

- (void)awakeFromNib  // always try to be the split view's delegate
{
    [super awakeFromNib];
    self.splitViewController.delegate = self;
}

// splitView delegate method
- (BOOL)splitViewController:(UISplitViewController *)svc 
   shouldHideViewController:(UIViewController *)vc 
              inOrientation:(UIInterfaceOrientation)orientation
{
    return YES;
}

- (void)splitViewController:(UISplitViewController *)svc
     willHideViewController:(UIViewController *)aViewController
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController:(UIPopoverController *)pc
{
    barButtonItem.title = @"所有文章";
    DaPengTi2ViewController* detailVC = [self.splitViewController.viewControllers lastObject];
    detailVC.splitViewBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc
     willShowViewController:(UIViewController *)aViewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    DaPengTi2ViewController* detailVC = [self.splitViewController.viewControllers lastObject];
    detailVC.splitViewBarButtonItem = nil;
}

- (IBAction)updatePostsList:(id)sender {
    [self.indicator startAnimating];
    [self getPostsFromServer];
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.indicator.center = CGPointMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2);
    [self.indicator startAnimating];
	[self getPostsFromServer];
}

-(void)getPostsFromServer{
    dispatch_async(kBgQueue, ^{
        //下载feed
        NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@/posts/feed.json",kSearchURL]];
        NSData* data = [NSData dataWithContentsOfURL:url];
        
        if (data) {
            NSArray* postsJson = [NSJSONSerialization 
                                  JSONObjectWithData:data //1
                                  options:kNilOptions 
                                  error:nil];
            // 下载所有图片,默认图片alt是文件名
            for (int i=0; i<[postsJson count]; i++) {
                NSError *downloadError;
                NSURLResponse *response;
                NSError *parseError;
                
                NSDictionary* postJson = [postsJson objectAtIndex:i];
                
                HTMLParser *parser = [[HTMLParser alloc] initWithString:[postJson objectForKey:@"content"] error:&parseError];
                if (!parseError) {
                    NSArray* imageNodes = [[parser body] findChildTags:@"img"];
                    for (HTMLNode* imgNode in imageNodes) {
                        NSString *urlString = [NSString stringWithFormat:@"%@%@",kSearchURL,[imgNode getAttributeNamed:@"src"]];
                        NSURL *imgUrl = [[NSURL alloc] initWithString:urlString];
                        NSMutableURLRequest *theRequest = [NSMutableURLRequest requestWithURL:imgUrl];
                        NSData* result = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&response error:&downloadError];
                        if (!downloadError) {
                            
                            NSString *fileName = [imgNode getAttributeNamed:@"alt"];
                            NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                            path = [path stringByAppendingPathComponent:fileName];
                            
                            [[NSFileManager defaultManager] createFileAtPath:path
                                                                    contents:result
                                                                  attributes:nil];
                        }
                    }
                    
                }
            }
        }
		dispatch_async(dispatch_get_main_queue(), ^{
//            [self.indicator stopAnimating];     
            if(data){            
	            //----- LIST ALL FILES -----
//                NSLog(@"LISTING ALL FILES FOUND");
//                
//                int Count;
//                NSString *path;
//                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//                path = [paths objectAtIndex:0] ;
//                NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
//                for (Count = 0; Count < (int)[directoryContent count]; Count++)
//                {
//                    NSLog(@"File %d: %@", (Count + 1), [directoryContent objectAtIndex:Count]);
//                }
				self.posts = [Post postsFromJSONDate:data];
                [self.tableView reloadData]; 
                DaPengTi2ViewController* detailVC = [self.splitViewController.viewControllers lastObject];
                [detailVC loadPosts:self.posts];
            } else {
                UIAlertView *message = [[UIAlertView alloc] initWithTitle:@"提醒!"
                                                                  message:@"服务不正常！请稍后重试."
                                                                 delegate:nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
                [message show];
            }
            
        });
    });
}

- (void)viewDidUnload
{
    [self setIndicator:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.posts count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    PostCell *postCell = (PostCell*)[tableView 
                                           dequeueReusableCellWithIdentifier:@"PostCell"];
	Post *post = [self.posts objectAtIndex:indexPath.row];
    postCell.textLabel.text = post.title;
    return postCell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//	Post *post = [self.posts objectAtIndex:indexPath.row];
//    DaPengTi2ViewController* detailVC = [self.splitViewController.viewControllers lastObject];
//	[detailVC updatePostViewForPost:post];
}

@end
