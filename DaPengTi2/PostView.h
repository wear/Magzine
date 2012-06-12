//
//  PostView.h
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PostView : UIScrollView<UIScrollViewDelegate>

@property(strong, nonatomic) NSAttributedString* attString;
@property(assign) float frameXOffset;
@property(assign) float frameYOffset;
@property (strong, nonatomic) NSMutableArray* frames;
@property(strong,nonatomic) NSArray* images;

-(void)buildFrames;
-(void)updateFrames;
-(void)setAttString:(NSAttributedString *)string withImages:(NSArray*)imgs;
@end
