//
//  MarkupParser.h
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class Post;


@interface MarkupParser : NSObject
@property (strong, nonatomic) NSString* font;
@property(assign,nonatomic) CGFloat fontSize;
@property (strong, nonatomic) UIColor* color;
@property (strong, nonatomic) UIColor* strokeColor;
@property (assign, readwrite) float strokeWidth;
@property(strong,nonatomic) NSAttributedString* title;


@property (strong, nonatomic) NSMutableArray* images;

-(NSAttributedString*)attrStringFromMarkupForPost:(Post*)post;
@end
