//
//  DaPengTi2ViewController.m
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DaPengTi2ViewController.h"
#import "MarkupParser.h"
#import "PostView.h"
#import "Post.h"

@interface DaPengTi2ViewController ()

@end

@implementation DaPengTi2ViewController
@synthesize postView;
@synthesize toolbar;
@synthesize post = _post;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;

// Puts the splitViewBarButton in our toolbar (and/or removes the old one).
// Must be called when our splitViewBarButtonItem property changes
//  (and also after our view has been loaded from the storyboard (viewDidLoad)).

- (void)handleSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
    if (_splitViewBarButtonItem) [toolbarItems removeObject:_splitViewBarButtonItem];
    if (splitViewBarButtonItem) [toolbarItems insertObject:splitViewBarButtonItem atIndex:0];
    self.toolbar.items = toolbarItems;
    _splitViewBarButtonItem = splitViewBarButtonItem;
}

- (void)setSplitViewBarButtonItem:(UIBarButtonItem *)splitViewBarButtonItem
{
    if (splitViewBarButtonItem != _splitViewBarButtonItem) {
        [self handleSplitViewBarButtonItem:splitViewBarButtonItem];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
//    NSArray *familyNames = [[NSArray alloc] initWithArray:[UIFont familyNames]];
//    NSArray *fontNames;
//    NSInteger indFamily, indFont;
//    for(indFamily=0;indFamily<[familyNames count];++indFamily)
//    {
//        NSLog(@"Family name: %@", [familyNames objectAtIndex:indFamily]);
//        fontNames =[[NSArray alloc]initWithArray:[UIFont fontNamesForFamilyName:[familyNames objectAtIndex:indFamily]]];
//        for(indFont=0; indFont<[fontNames count]; ++indFont)
//        {
//            NSLog(@" Font name: %@",[fontNames objectAtIndex:indFont]);
//        }
//    }
}

-(void)updatePostViewForPost:(Post*)post{
	if (!_post || [post.postId integerValue] != [_post.postId integerValue]) {
        for (UIView *view in self.postView.subviews) {
            [view removeFromSuperview];
        }
        self.post = post;
        
        MarkupParser* p = [[MarkupParser alloc] init];
        NSAttributedString* attString = [p attrStringFromMarkup:post.content];
        [self.postView setAttString:attString withImages: p.images];
        [self.postView buildFrames];
    }
}

- (void)viewDidUnload
{
    [self setPostView:nil];
    [self setToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(self.post){
        for (UIView *view in self.postView.subviews) {
            [view removeFromSuperview];
        }
        
        MarkupParser* p = [[MarkupParser alloc] init];
        NSAttributedString* attString = [p attrStringFromMarkup:self.post.content];
        [self.postView setAttString:attString withImages: p.images];
        [self.postView buildFrames];
    }	
}

@end
