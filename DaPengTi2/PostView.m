//
//  PostView.m
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PostView.h"
#import "PostColumnVIew.h"
#import <CoreText/CoreText.h>
#import "MarkupParser.h"
#import "Post.h"
#define FrameXOffset 60
#define FrameYOffset 60
#define FrameSplitOffset 10

@interface PostView() 
@property(strong,nonatomic) MarkupParser* parser;
@end

@implementation PostView
@synthesize attString = _attString;
@synthesize frames = _frames;
@synthesize images = _images;
@synthesize index;
@synthesize parser = _parser;

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
    [self setAttString:attString withImages: self.parser.images];
    [self buildFrames];
}

-(void)buildFrames{
    self.pagingEnabled = YES;
    self.delegate = self;
    self.bounces = NO;
    self.frames = [NSMutableArray array];
    
    CGMutablePathRef textPath = CGPathCreateMutable(); //2
    CGRect textFrame = CGRectInset(self.frame, FrameXOffset, FrameYOffset);
    CGPathAddRect(textPath, NULL, textFrame);

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)self.attString);
    
    int textPos = 0; //3
    int columnIndex = 0;
    
    while (textPos < [_attString length]) { //4
        CGPoint colOffset = CGPointMake( (columnIndex+1)*FrameXOffset-(columnIndex%2==0 ? 0 :1)*FrameXOffset/2 + columnIndex*(textFrame.size.width/2), FrameYOffset );
        //如果是双数col就双倍offset
        CGRect colRect = CGRectMake(0, 0 , textFrame.size.width/2-FrameXOffset/2, textFrame.size.height);
        
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, colRect);
        
        //use the column path
        CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(textPos, 0), path, NULL);
        CFRange frameRange = CTFrameGetVisibleStringRange(frame); //5
        //create an empty column view
        PostColumnView* content = [[PostColumnView alloc] initWithFrame: CGRectMake(0, 0, self.contentSize.width, self.contentSize.height)];
        content.backgroundColor = [UIColor clearColor];
        content.frame = CGRectMake(colOffset.x, colOffset.y, colRect.size.width, colRect.size.height) ;
        
		//set the column view contents and add it as subview
        if([self.images count] > 0) [self attachImagesWithFrame:frame inColumnView:content atIndex:columnIndex];
        
        [content setPostFrame:(__bridge_transfer id)frame];  //6   
        [self.frames addObject: (__bridge id)frame];
        [self addSubview: content];
        
        //prepare for next frame
        textPos += frameRange.length;
        
        //CFRelease(frame);
		CGPathRelease(path);
        
        columnIndex++;
    }
    
    //set the total width of the scroll view
    int totalPages = (columnIndex+1) / 2; //7
    self.contentSize = CGSizeMake(totalPages*self.bounds.size.width, textFrame.size.height);
	CFRelease(textPath);
    CFRelease(framesetter);
}

-(void)attachImagesWithFrame:(CTFrameRef)f inColumnView:(PostColumnView*)col atIndex:(NSUInteger)colIndex
{
    //drawing images
    NSArray *lines = (__bridge NSArray *)CTFrameGetLines(f); //1
    
    CGPoint origins[[lines count]];
    CTFrameGetLineOrigins(f, CFRangeMake(0, 0), origins); //2
    
    int imgIndex = 0; //3
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
                NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
                path = [path stringByAppendingPathComponent:[nextImage objectForKey:@"alt"]];

                UIImage *img = [UIImage imageWithContentsOfFile:path];

                CGPathRef pathRef = CTFrameGetPath(f); //10
                CGRect colRect = CGPathGetBoundingBox(pathRef);
                
                CGRect imgBounds = CGRectOffset(runBounds, colRect.origin.x - 2*FrameXOffset - self.contentOffset.x-(self.frame.size.width+PagingScrollPadding)*self.index, colRect.origin.y - FrameYOffset - self.frame.origin.y);
                NSLog(@"imgBounds　%@",NSStringFromCGRect(imgBounds));
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


@end
