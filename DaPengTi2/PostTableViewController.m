//
//  PostTableViewController.m
//  DaPengTi2
//
//  Created by  on 12-6-13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PostTableViewController.h"
#import "DaPengTi2ViewController.h"
#import "Issue.h"
#import "Post.h"
#import "Post+feed.h"
#import "Picture.h"
#import "Picture+feed.h"
#import "PostCell.h"
#import "HTMLNode.h"

@interface PostTableViewController ()
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
@property(strong,nonatomic) NSArray* posts;
@property(strong,nonatomic) NSOperationQueue* queue;

-(void)sayDone:(id)sender;
@end

@implementation PostTableViewController
@synthesize indicator = _indicator;
@synthesize posts = _posts;
@synthesize issue = _issue;
@synthesize queue = _queue;

- (void)awakeFromNib  // always try to be the split view's delegate
{
    [super awakeFromNib];
    self.queue = [[NSOperationQueue alloc] init];
    [self.queue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
}

- (IBAction)updatePostsList:(id)sender {
    [self getPostsFromHost];
}

-(void)getPostsFromHost{
    NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@/issues/%i/feed.json",kSearchURL,[self.issue.issueID intValue]]];
    NSData* data = [NSData dataWithContentsOfURL:url];	
    
    NSArray* issueJson = [NSJSONSerialization 
                          JSONObjectWithData:data 
                          options:kNilOptions 
                          error:nil];
    
    NSArray* postsDict =  [issueJson valueForKey:@"posts"];
    NSArray* picturesDict = [issueJson valueForKey:@"pictures"];
    id appDelegate = (id)[[UIApplication sharedApplication] delegate];
    
    NSManagedObjectContext *context  = [appDelegate managedObjectContext];    
    
    for (NSDictionary* postDict in postsDict) {
       [self.issue addPostsObject:[Post postsFromFeed:postDict inManagedObjectContext:context]];
    }
    
    for (NSDictionary* pictureDict in picturesDict) {
        [self.issue addPicturesObject:[Picture pictureFromFeed:pictureDict inManagedObjectContext:context]];
        
        NSString *imageUrl = [pictureDict valueForKey:@"url"];
        NSString *identifier = [pictureDict valueForKey:@"identifier"];
        
        NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        path = [path stringByAppendingPathComponent:identifier];

        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSBlockOperation *opration = [NSBlockOperation blockOperationWithBlock:^{
                NSString *urlString = [NSString stringWithFormat:@"%@%@",kSearchURL,imageUrl];
                NSURL *imgUrl = [[NSURL alloc] initWithString:urlString];
                
                NSData *imageData = [[NSData alloc] initWithContentsOfURL:imgUrl];
                [[NSFileManager defaultManager] createFileAtPath:path contents:imageData attributes:nil];
            }];
			[self.queue addOperation:opration];
        } 
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object 
                         change:(NSDictionary *)change context:(void *)context
{
    if (object == self.queue && [keyPath isEqualToString:@"operations"]) {
        if ([self.queue.operations count] == 0) {
            // Do something here when your queue has completed
            [self performSelectorOnMainThread:@selector(sayDone:) withObject:nil waitUntilDone:NO];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object 
                               change:change context:context];
    }
}

-(void)sayDone:(id)sender{
    // 需要改进，不用一次取出所有
    NSError* error;
    id appDelegate = (id)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context  = [appDelegate managedObjectContext];
    [context save:&error];
    
	self.posts = [self.issue.posts allObjects];
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.posts = [self.issue.posts allObjects];
    DaPengTi2ViewController* detailVC = [self.splitViewController.viewControllers lastObject];
    [detailVC loadPosts:self.posts];
    
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
    DaPengTi2ViewController* detailVC = [self.splitViewController.viewControllers lastObject];
	[detailVC showSpecifyPage:indexPath.row];
}

@end
