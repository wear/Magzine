//
//  IssuesTableViewController.m
//  DaPengTi2
//
//  Created by  on 12-6-27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "IssuesTableViewController.h"
#import "DaPengTi2ViewController.h"
#import "Issue.h"
#import "Issue+Rss.h"
#import "PostTableViewController.h"

@interface IssuesTableViewController ()

@end

@implementation IssuesTableViewController
@synthesize issues = _issues;

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


- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.issues = [[NSMutableArray alloc] init];
    
    [self getIssuesFromHost];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
    return [self.issues count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"IssueCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"IssueCell"];
    }
    
    Issue *issue = [self.issues objectAtIndex:indexPath.row];
    cell.textLabel.text = issue.title;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showPosts" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showPosts"])
	{
        NSInteger selectedIndex = [[self.tableView indexPathForSelectedRow] row];	
        Issue *issue = [self.issues objectAtIndex:selectedIndex];
        [(PostTableViewController*)segue.destinationViewController setIssue:issue];
	}
}

//remote fetch
-(void)getIssuesFromHost{
    dispatch_async(kBgQueue, ^{
        //下载feed
        NSURL *url = [NSURL URLWithString:[[NSString alloc] initWithFormat:@"%@/issues/list.json",kSearchURL]];
        NSData* data = [NSData dataWithContentsOfURL:url];
        NSArray* issuesJsons = [NSJSONSerialization 
                              JSONObjectWithData:data //1
                              options:kNilOptions 
                              error:nil];
        dispatch_async(dispatch_get_main_queue(), ^{
            id appDelegate = (id)[[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context  = [appDelegate managedObjectContext];
            NSError *error = nil;
            // 下载期刊信息
            for (NSDictionary* issueJson in issuesJsons) {
				[self.issues addObject:[Issue issueFromRssFeed:issueJson inManagedObjectContext:context]];
            }
            [context save:&error];
            [self.tableView reloadData];
        });
    });
}


@end
