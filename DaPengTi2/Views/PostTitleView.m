//
//  PostTitleView.m
//  DaPengTi2
//
//  Created by  on 12-6-21.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "PostTitleView.h"
#import <CoreText/CoreText.h>

@implementation PostTitleView
@synthesize titleFrame = _titleFrame;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    // Drawing code
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Flip the coordinate system
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CTFrameDraw((__bridge CTFrameRef)self.titleFrame, context);
}

@end
