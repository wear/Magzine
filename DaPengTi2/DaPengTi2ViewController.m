//
//  DaPengTi2ViewController.m
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "DaPengTi2ViewController.h"
#import "PostView.h"
#import "Post.h"
#import "MarkupParser.h"

@interface DaPengTi2ViewController () 
@property(strong,nonatomic) NSArray* postList;

- (void)tilePosts;
- (void)configurePost:(PostView *)page forIndex:(NSUInteger)index;
@end

@implementation DaPengTi2ViewController
@synthesize pagingScrollView = _pagingScrollView;
@synthesize toolbar;
@synthesize post = _post;
@synthesize splitViewBarButtonItem = _splitViewBarButtonItem;
@synthesize recycledPages = _recycledPages;
@synthesize visiblePages = _visiblePages;
@synthesize postList = _postList;

-(void)loadPosts:(NSArray *)posts{
    self.postList = posts;
    self.pagingScrollView.contentSize = CGSizeMake(self.pagingScrollView.bounds.size.width * [self.postList count],
                                               self.pagingScrollView.bounds.size.height); 
    [self tilePosts];
//    for (int i=0;i<5;i++) {
//        Post* post= [posts objectAtIndex:i];
//        PostView* postView = [[PostView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//        MarkupParser *parser = [[MarkupParser alloc] init];
//        NSAttributedString* attString = [parser attrStringFromMarkupForPost:post];
//        [postView setAttString:attString withImages:parser.images];
//        [postView buildFrames];
//        
//        [self configurePost:postView forIndex:i];
//        [self.view addSubview:postView];
//    }
}

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

-(void)viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    self.pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
    self.pagingScrollView.pagingEnabled = YES;
    self.pagingScrollView.backgroundColor = [UIColor redColor];
    self.pagingScrollView.showsVerticalScrollIndicator = NO;
    self.pagingScrollView.showsHorizontalScrollIndicator = NO;
    self.pagingScrollView.delegate = self;
    [self.view addSubview:self.pagingScrollView];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Step 2: prepare to tile content
    self.recycledPages = [[NSMutableSet alloc] init];
    self.visiblePages  = [[NSMutableSet alloc] init];

    self.pagingScrollView.contentSize = CGSizeMake(self.pagingScrollView.bounds.size.width * [self.postList count],
                                               self.pagingScrollView.bounds.size.height); 
}

- (void)viewDidUnload
{
    [self setToolbar:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    if(self.post){
//        for (UIView *view in self.postView.subviews) {
//            [view removeFromSuperview];
//        }
//        
//        MarkupParser* p = [[MarkupParser alloc] init];
//        NSAttributedString* attString = [p attrStringFromMarkup:self.post.content];
//        [self.postView setAttString:attString withImages: p.images];
//        [self.postView buildFrames];
//    }	
}


- (void)configurePost:(PostView *)page forIndex:(NSUInteger)index
{
    page.index = index;
    page.frame = [self frameForPageAtIndex:index];
    page.backgroundColor = [UIColor brownColor];
        
    // Use tiled images
    [page displayTiledPost:[self.postList objectAtIndex:index]];
}

#pragma mark -
#pragma mark Tiling and page configuration

- (void)tilePosts
{
    // Calculate which pages are visible
    CGRect visibleBounds = _pagingScrollView.bounds;
    int firstNeededPageIndex = floorf(CGRectGetMinX(visibleBounds) / CGRectGetWidth(visibleBounds));
    int lastNeededPageIndex  = floorf((CGRectGetMaxX(visibleBounds)-1) / CGRectGetWidth(visibleBounds));
    firstNeededPageIndex = MAX(firstNeededPageIndex, 0);
    lastNeededPageIndex  = MIN(lastNeededPageIndex, [self.postList count] - 1);
    // Recycle no-longer-visible pages 
    for (PostView *postView in self.visiblePages) {
        if (postView.index < firstNeededPageIndex || postView.index > lastNeededPageIndex) {
            [self.recycledPages addObject:postView];
            [postView removeFromSuperview];
        }
    }
    [self.visiblePages minusSet:self.recycledPages];
    
    // add missing pages
    for (int index = firstNeededPageIndex; index <= lastNeededPageIndex; index++) {
        if (![self isDisplayingPageForIndex:index]) {
            PostView *page = [self dequeueRecycledPage];
            if (page == nil) {
                page = [[PostView alloc] init];
            }
            [self configurePost:page forIndex:index];
            [self.pagingScrollView addSubview:page];
            [_visiblePages addObject:page];
        } else {
        }
    }    
}

- (PostView *)dequeueRecycledPage
{
    PostView *page = [_recycledPages anyObject];
    if (page) {
//        [[page retain] autorelease];
        [_recycledPages removeObject:page];
    }
    return page;
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index
{
    BOOL foundPage = NO;
    for (PostView *page in _visiblePages) {
        if (page.index == index) {
            foundPage = YES;
            break;
        }
    }
    return foundPage;
}



#pragma mark -
#pragma mark  Frame calculations
#define PADDING  10

- (CGRect)frameForPagingScrollView {
    CGRect frame = [[UIScreen mainScreen] bounds];
    frame.origin.x -= PADDING;
    frame.size.width += (2 * PADDING);
    return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
    CGRect pageFrame = pagingScrollViewFrame;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (pagingScrollViewFrame.size.width * index) + PADDING;
    return pageFrame;
}

#pragma mark -
#pragma mark ScrollView delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self tilePosts];
}

@end
