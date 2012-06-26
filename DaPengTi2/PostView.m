//
//  PostView.m
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PostView.h"
#import "PostColumnView.h"
#import "PostTitleView.h"
#import <CoreText/CoreText.h>
#import "MarkupParser.h"
#import "Post.h"

@interface PostView() 
@property(strong,nonatomic) MarkupParser* parser;
@property(assign) int totalPages;
@end

@implementation PostView
@synthesize attString = _attString;
@synthesize columns = _columns;
@synthesize images = _images;
@synthesize index;
@synthesize parser = _parser;
@synthesize firstPageContent = _firstPageContent;
@synthesize totalPages;


-(MarkupParser*)parser{
    if (!_parser) {
        _parser = [[MarkupParser alloc] init];
    }
    return _parser;
}

-(void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs
{
    self.attString = string;
	self.images = imgs;
}

-(void)displayTiledPost:(Post*)post{
    // 重设colums和contentSize
	for (UIView* view in self.subviews) {
        [view removeFromSuperview];
    }
    self.contentSize = self.frame.size;
    [self.parser.images removeAllObjects];
    
    NSAttributedString* attString = [self.parser attrStringFromMarkupForPost:post];
    [self setAttString:attString withImages:self.parser.images];
    [self buildFrames:post.layout];
}


-(void)buildFrames:(NSString*)layout{
    self.pagingEnabled = YES;
    self.delegate = self;
    self.bounces = NO;
    BOOL haveHeadline = FALSE;
    
    //加入标题
    CGMutablePathRef titlePath = CGPathCreateMutable(); //1
    CGPathAddRect(titlePath, NULL, CGRectMake(0, 0, self.frame.size.width-2*FrameXOffset, TitleHeight));
    
    CTFramesetterRef titleFramesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.parser.title); //3
    CTFrameRef titleFrame = CTFramesetterCreateFrame(titleFramesetter,CFRangeMake(0, 0), titlePath, NULL);
    
	PostTitleView *titleView = [[PostTitleView alloc] initWithFrame:CGRectMake(FrameXOffset, 2*FrameYOffset, self.frame.size.width-2*FrameXOffset, TitleHeight)];
    titleView.titleFrame = (__bridge_transfer id)titleFrame;
    titleView.backgroundColor = [UIColor clearColor];
    [self.firstPageContent addObject:titleView];
    [self addSubview:titleView];
    
    CFRelease(titleFramesetter);
    CGPathRelease(titlePath);
    
    // 首屏大图
    if ([layout isEqualToString:@"headline"]) {
        for (NSDictionary* imageInfo in self.images) {
            if ([[imageInfo valueForKey:@"class"] isEqualToString:@"headline"]) {
                NSString* filename = [[self.images objectAtIndex:0] valueForKey:@"alt"];
                UIImage* headlineImage = [self getImageData:filename];
                UIImageView* headlineImageView =  [[UIImageView alloc] initWithImage:headlineImage];
                headlineImageView.frame = CGRectMake(0, TitlePadding+TitleHeight, self.frame.size.width, HeadLineHeight);
                [self.firstPageContent addObject:headlineImageView];
                [self addSubview:headlineImageView];
            }
        }
        haveHeadline = TRUE;
    }
    
    CGMutablePathRef textPath = CGPathCreateMutable(); //2
    CGRect textFrame = CGRectInset(self.frame, FrameXOffset, FrameYOffset);
    CGPathAddRect(textPath, NULL, textFrame);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attString);
    
    int textPos = 0; //3
    int columnIndex = 0;
    
    while (textPos < [_attString length]) { //4
        CGPoint  colOffset = CGPointMake( (columnIndex+1)*FrameXOffset-(columnIndex%2==0 ? 0 :1)*FrameXOffset/2 + columnIndex*(textFrame.size.width/2), FrameYOffset );
        
        CGRect colRect;
        if (columnIndex >= 2) {
            //如果是双数col就双倍offset
            colRect =  CGRectMake(0, 0 , textFrame.size.width/2-FrameXOffset/2, textFrame.size.height);
        } else {
            colOffset = CGPointMake( (columnIndex+1)*FrameXOffset-(columnIndex%2==0 ? 0 :1)*FrameXOffset/2 + columnIndex*(textFrame.size.width/2), FrameYOffset+TitleHeight+TitlePadding+(haveHeadline ? HeadLineHeight : 0));
            colRect =  CGRectMake(0, 0, textFrame.size.width/2-FrameXOffset/2, textFrame.size.height - TitleHeight -TitlePadding-(haveHeadline ? HeadLineHeight : 0));
        }
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, colRect);
        
        //use the column path
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
        CFRange frameRange = CTFrameGetVisibleStringRange(frame); //5
        //create an empty column view
        PostColumnView* content = [[PostColumnView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
        content.backgroundColor = [UIColor clearColor];
        content.frame = CGRectMake(colOffset.x, colOffset.y, colRect.size.width, colRect.size.height) ;
        
		//set the column view contents and add it as subview
        if([self.images count] > (haveHeadline ? 1 : 0)) [self attachImagesWithFrame:frame inColumnView:content atIndex:columnIndex headline:haveHeadline];
        
        [content setPostFrame:(__bridge_transfer id)frame];  //6   
//        [self.columns addObject: content];
        [self addSubview: content];
        
        //prepare for next frame
        textPos += frameRange.length;
        
        //CFRelease(frame);
		CGPathRelease(path);
        columnIndex++;
    }
    
    //set the total width of the scroll view
    self.totalPages = (columnIndex+1) / 2; //7
    self.contentSize = CGSizeMake(self.totalPages*self.bounds.size.width, textFrame.size.height);
    
	CGPathRelease(textPath);
    CFRelease(framesetter);
}

-(void)attachImagesWithFrame:(CTFrameRef)f inColumnView:(PostColumnView*)col atIndex:(NSUInteger)colIndex headline:(BOOL)haveHeadline
{
    //drawing images
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(f); //1
    
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(f, CFRangeMake(0, 0), origins); //2
    
    int imgIndex = haveHeadline ? 1 : 0; //3
    NSDictionary* nextImage = [self.images objectAtIndex:imgIndex];
    int imgLocation = [[nextImage objectForKey:@"location"] intValue];
    
    //find images for the current column
    CFRange frameRange = CTFrameGetVisibleStringRange(f); //4
    while ( imgLocation < frameRange.location ) {
        imgIndex++;
        if (imgIndex>=[self.images count]) return; //quit if no images for this column
        nextImage = [self.images objectAtIndex:imgIndex];
        imgLocation = [[nextImage objectForKey:@"location"] intValue];
    }
    
    NSUInteger lineIndex = 0;
    for (id lineObj in lines) { //5
        CTLineRef line = (__bridge CTLineRef)lineObj;
        
        for (id runObj in (__bridge NSArray *)CTLineGetGlyphRuns(line)) { //6
            CTRunRef run = (__bridge CTRunRef)runObj;
            CFRange runRange = CTRunGetStringRange(run);
            if ( runRange.location <= imgLocation && runRange.location+runRange.length > imgLocation ) { //7

	            CGRect runBounds;
	            CGFloat ascent;//height above the baseline
	            CGFloat descent;//height below the baseline
	            runBounds.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL); //8
	            runBounds.size.height = ascent + descent;

	            CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL); //9
	            runBounds.origin.x = origins[lineIndex].x + self.frame.origin.x + xOffset + FrameXOffset;
	            runBounds.origin.y = origins[lineIndex].y + self.frame.origin.y + FrameYOffset;
	            runBounds.origin.y -= descent;

                // 如果没有图片怎么办？
				UIImage *img = [self getImageData:[nextImage objectForKey:@"alt"]];

                CGPathRef pathRef = CTFrameGetPath(f); //10
                CGRect colRect = CGPathGetBoundingBox(pathRef);
                
                CGRect imgBounds = CGRectOffset(runBounds, colRect.origin.x - 2*FrameXOffset - self.contentOffset.x-(self.frame.size.width+PagingScrollPadding)*self.index, colRect.origin.y - FrameYOffset - self.frame.origin.y);
                [col.images addObject: [NSArray arrayWithObjects:img, NSStringFromCGRect(imgBounds) ,[NSNumber numberWithInteger:self.index], nil]]; 

                //load the next image //12
                imgIndex++;
                if (imgIndex < [self.images count]) {
                    nextImage = [self.images objectAtIndex: imgIndex];
                    imgLocation = [[nextImage objectForKey: @"location"] intValue];
                }
                
            }
        }
        lineIndex++;
    }
}

-(UIImage*)getImageData:(NSString*)filename{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:filename];
    
    UIImage *img = [UIImage imageWithContentsOfFile:path];
    return img;
}

@end
