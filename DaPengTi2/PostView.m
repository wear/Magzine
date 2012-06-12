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
#define ViewXOffset 40
#define ViewYOffset 40
#define FrameXOffset 40
#define FrameYOffset 40
#define FrameSplitOffset 30

@implementation PostView
@synthesize attString = _attString;
@synthesize frameXOffset = _frameXOffset;
@synthesize frameYOffset = _frameYOffset;
@synthesize frames = _frames;
@synthesize images = _images;

-(void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs
{
	if (!_attString) {
        //設定對齊方式
       CTTextAlignment alignment = kCTJustifiedTextAlignment;
       CTParagraphStyleSetting alignmentStyle;
       alignmentStyle.spec=kCTParagraphStyleSpecifierAlignment;
       alignmentStyle.valueSize=sizeof(alignment);
       alignmentStyle.value=&alignment;
       
       //設定行高
       CGFloat lineSpace1= 32;
       CTParagraphStyleSetting lineSpaceStyle1;
       lineSpaceStyle1.spec=kCTParagraphStyleSpecifierMinimumLineHeight;
       lineSpaceStyle1.valueSize=sizeof(lineSpace1);
       lineSpaceStyle1.value=&lineSpace1;
       
       //换行模式
       CTLineBreakMode lineBreakMode = kCTLineBreakByWordWrapping;
       CTParagraphStyleSetting lineBreak;
       lineBreak.spec = kCTParagraphStyleSpecifierLineBreakMode;
       lineBreak.valueSize = sizeof(lineBreakMode);
       lineBreak.value = &lineBreakMode;
       
       CTParagraphStyleSetting settings[3]={
           alignmentStyle,lineSpaceStyle1,lineBreak
       };
       
       CTParagraphStyleRef paragraphStyle = CTParagraphStyleCreate(settings, sizeof(settings));
        
        NSMutableAttributedString* stringCopy = [[NSMutableAttributedString alloc] initWithAttributedString:string];
		//設定段落樣式
        [stringCopy addAttribute:(id)kCTParagraphStyleAttributeName value:(__bridge id)paragraphStyle range:NSMakeRange(0,[string length])];
        
        _attString = stringCopy;
        CFRelease(paragraphStyle);
        
        self.images = imgs;
    }	
}

-(void)buildFrames{

    _frameXOffset = ViewXOffset; //1
    _frameYOffset = ViewYOffset;
    self.pagingEnabled = YES;
    self.delegate = self;
    self.frames = [NSMutableArray array];
    
    CGMutablePathRef path = CGPathCreateMutable(); //2
    CGRect textFrame = CGRectInset(self.bounds, _frameXOffset, _frameYOffset);
    CGPathAddRect(path, NULL, textFrame );

    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((__bridge CFAttributedStringRef)_attString);
    
    int textPos = 0; //3
    int columnIndex = 0;
    
    while (textPos < [_attString length]) { //4
        CGPoint colOffset = CGPointMake( (columnIndex+1)*_frameXOffset + columnIndex*(textFrame.size.width/2), FrameYOffset );
        CGRect colRect = CGRectMake(0, 0 , textFrame.size.width/2-FrameSplitOffset, textFrame.size.height);
        
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
        [self attachImagesWithFrame:frame inColumnView:content];
        [content setPostFrame:(__bridge id)frame];  //6   
        [self.frames addObject: (__bridge id)frame];
        [self addSubview: content];
        
        //prepare for next frame
        textPos += frameRange.length;
        
        //CFRelease(frame);
        CFRelease(path);
        
        columnIndex++;
    }
    
    //set the total width of the scroll view
    int totalPages = (columnIndex+1) / 2; //7
    self.contentSize = CGSizeMake(totalPages*self.bounds.size.width, textFrame.size.height);
    
}

-(void)attachImagesWithFrame:(CTFrameRef)f inColumnView:(PostColumnView*)col
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
//	NSLog(@"framelocation is %ld, img location is %d",frameRange.location,imgLocation);
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
	            runBounds.origin.x = origins[lineIndex].x + self.frame.origin.x + xOffset + _frameXOffset;
	            runBounds.origin.y = origins[lineIndex].y + self.frame.origin.y + _frameYOffset;
	            runBounds.origin.y -= descent;

                UIImage *img = [UIImage imageNamed:[nextImage objectForKey:@"src"] ];

                CGPathRef pathRef = CTFrameGetPath(f); //10
                CGRect colRect = CGPathGetBoundingBox(pathRef);
                
                CGRect imgBounds = CGRectOffset(runBounds, colRect.origin.x - _frameXOffset - self.contentOffset.x, colRect.origin.y - _frameYOffset - self.frame.origin.y);

                [col.images addObject: //11
                 [NSArray arrayWithObjects:img, NSStringFromCGRect(imgBounds) , nil]
                 ]; 

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


-(void)updateFrames{
	self.frames = nil;
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [self buildFrames];
}


@end
