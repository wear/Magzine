//
//  MarkupParser.m
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MarkupParser.h"
#import "HTMLParser.h"
#import "Post.h"
#import <CoreText/CoreText.h>

/* Callbacks */
static void deallocCallback( void* ref ){
	CFRelease(ref);
}
static CGFloat ascentCallback( void *ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"height"] floatValue];
}
static CGFloat descentCallback( void *ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"descent"] floatValue];
}
static CGFloat widthCallback( void* ref ){
    return [(NSString*)[(__bridge NSDictionary*)ref objectForKey:@"width"] floatValue];
}

@implementation MarkupParser
@synthesize font, color, strokeColor, strokeWidth;
@synthesize fontSize;
@synthesize images = _images;
@synthesize title = _title;

-(id)init
{
    self = [super init];
    if (self) {
        self.font = @"STZhongsong";
        self.color = [UIColor blackColor];
        self.strokeColor = [UIColor whiteColor];
        self.strokeWidth = 0.0;
        self.fontSize = 16.;
        self.images = [NSMutableArray array];
    }
    return self;
}


// 构建node tree,默认全部内容放在class为entry-content的div中
// 所有段落被p标签包含
-(NSAttributedString*)attrStringFromMarkupForPost:(Post*)post
{
	//初始化内容
	NSMutableAttributedString* aString = [[NSMutableAttributedString alloc] initWithString:@""]; 
    NSError *error = nil;
    
    HTMLParser *parser = [[HTMLParser alloc] initWithString:post.content error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    
    HTMLNode *bodyNode = [parser body];
    
    int nodeCount = 0;
    NSArray* entryNodes = [bodyNode children];
    
    //开始设置默认样式
    //字体
    CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)self.font,
                                             self.fontSize, NULL);
    
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
    
    NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                           (id)self.color.CGColor, kCTForegroundColorAttributeName,
                           (__bridge_transfer id)fontRef, kCTFontAttributeName,
                           (id)self.strokeColor.CGColor, (NSString *)kCTStrokeColorAttributeName,
                           (__bridge_transfer id)paragraphStyle,(id)kCTParagraphStyleAttributeName,
                           (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                           nil];
    
	//标题与样式
    NSMutableDictionary *titleAttrs = [NSMutableDictionary dictionary];
    [titleAttrs setDictionary:attrs];
    CTFontRef h1FontRef = CTFontCreateWithName((__bridge CFStringRef)@"STZhongsong",
                                               36., NULL);
    //設定行高
    CGFloat lineSpaceh1= 54;
    CTParagraphStyleSetting lineSpaceStyleh1;
    lineSpaceStyleh1.spec=kCTParagraphStyleSpecifierMinimumLineHeight;
    lineSpaceStyleh1.valueSize=sizeof(lineSpaceh1);
    lineSpaceStyleh1.value=&lineSpaceh1;
    
    CTParagraphStyleSetting h1settings[1]={
        lineSpaceStyleh1
    };
    CTParagraphStyleRef h1paragraphStyle = CTParagraphStyleCreate(h1settings, sizeof(h1settings));
    
    [titleAttrs setValue:(__bridge_transfer id)h1FontRef forKey:(NSString *)kCTFontAttributeName];
    [titleAttrs setValue:(__bridge_transfer id)h1paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];

    self.title = [[NSAttributedString alloc] initWithString:post.title attributes:titleAttrs];
        
    
    // 顺序解析标签
    while ([entryNodes count] > nodeCount) {
        
        HTMLNode* currentNode = [entryNodes objectAtIndex:nodeCount];
        NSString *currentNodeContent = [currentNode contents];

        if ([[currentNode tagName] isEqualToString:@"p"]) {
            
            if (currentNodeContent) [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[currentNodeContent stringByAppendingString:@"\r\r"] attributes:attrs]];
            
            // 小标题
            for (HTMLNode *strongNode in [currentNode findChildTags:@"strong"]) {
                CTFontRef strongFontRef = CTFontCreateWithName((__bridge CFStringRef)@"STZhongsong",
                                                    21., NULL);
            	NSMutableDictionary *mutAttrs = [[NSMutableDictionary alloc] init];
            	[mutAttrs setDictionary:attrs];
                [mutAttrs setValue:(__bridge id)strongFontRef forKey:(NSString *)kCTFontAttributeName];
                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[[strongNode contents] stringByAppendingString:@"\r\r"] attributes:mutAttrs]];
            }
            
            // 图片
			for(HTMLNode *imgNode in [currentNode findChildTags:@"img"]){
                NSDictionary* imginfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [imgNode getAttributeNamed:@"width"], @"width",
                                         [imgNode getAttributeNamed:@"height"], @"height",
                                         [NSNumber numberWithInteger:[aString length]],@"location",
                                         [imgNode getAttributeNamed:@"src"],@"src",
                                         [imgNode getAttributeNamed:@"alt"],@"alt",
                                         [imgNode getAttributeNamed:@"class"],@"class",
                                         post.postID,@"postID",
                                         nil];
                
                [self.images addObject:imginfo];
                
                if (![[imginfo valueForKey:@"class"] isEqualToString:@"headline"]) {
                    //render empty space for drawing the image in the text //1
                    CTRunDelegateCallbacks callbacks;
                    callbacks.version = kCTRunDelegateVersion1;
                    callbacks.getAscent = ascentCallback;
                    callbacks.getDescent = descentCallback;
                    callbacks.getWidth = widthCallback;
                    callbacks.dealloc = deallocCallback;
                    
                    NSDictionary* imgAttr = [NSDictionary dictionaryWithObjectsAndKeys: //2
                                             [imgNode getAttributeNamed:@"width"], @"width",
                                             [imgNode getAttributeNamed:@"height"], @"height",
                                             nil];
                    
                    CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks,(__bridge_retained void*)imgAttr); //3
                    NSDictionary *attrDictionaryDelegate = [NSDictionary dictionaryWithObjectsAndKeys:
                                                            //set the delegate
                                                            (__bridge_transfer id)delegate, (NSString*)kCTRunDelegateAttributeName,
                                                            nil];
                    
                    //add a space to the text so that it can call the delegate
                    [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:attrDictionaryDelegate]];
                }
            }
        }
        nodeCount += 1;
    }
    return (NSAttributedString*)aString;
}

@end
