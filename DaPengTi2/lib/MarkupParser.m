//
//  MarkupParser.m
//  DaPengTi2
//
//  Created by  on 12-6-11.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MarkupParser.h"
#import "HTMLParser.h"
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
@synthesize images;

-(id)init
{
    self = [super init];
    if (self) {
        self.font = @"STZhongsong";
        self.color = [UIColor blackColor];
        self.strokeColor = [UIColor whiteColor];
        self.strokeWidth = 0.0;
        self.fontSize = 21.;
        self.images = [NSMutableArray array];
    }
    return self;
}


// 构建node tree,默认全部内容放在class为entry-content的div中
// 所有段落被p标签包含,h元素除外
-(NSAttributedString*)attrStringFromMarkup:(NSString*)markup
{
	//初始化内容
	NSMutableAttributedString* aString = [[NSMutableAttributedString alloc] initWithString:@""]; 
    NSError *error = nil;
    
    HTMLParser *parser = [[HTMLParser alloc] initWithString:markup error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    
    HTMLNode *bodyNode = [parser body];
    
    int nodeCount = 0;
    NSArray* entryNodes = [bodyNode children];
    
    
    // 顺序解析标签
    while ([entryNodes count] > nodeCount) {
        
        HTMLNode* currentNode = [entryNodes objectAtIndex:nodeCount];
        NSString *currentNodeContent = [currentNode contents];
        
//        if ([[currentNode tagName] isEqualToString:@"h1"]) {    
//            NSMutableDictionary *mutAttrs = [[NSMutableDictionary alloc] init];
//            [mutAttrs setDictionary:attrs];
//            CTFontRef h1FontRef = CTFontCreateWithName((__bridge CFStringRef)@"STHeitiSC-Medium",
//                                                     36., NULL);
//            //設定行高
//            CGFloat lineSpaceh1= 32;
//            CTParagraphStyleSetting lineSpaceStyleh1;
//            lineSpaceStyleh1.spec=kCTParagraphStyleSpecifierMinimumLineHeight;
//            lineSpaceStyleh1.valueSize=sizeof(lineSpaceh1);
//            lineSpaceStyleh1.value=&lineSpaceh1;
//            
//            CTParagraphStyleSetting h1settings[1]={
//                lineSpaceStyleh1
//            };
//            CTParagraphStyleRef h1paragraphStyle = CTParagraphStyleCreate(h1settings, sizeof(h1settings));
//            
//            [mutAttrs setValue:(__bridge id)h1FontRef forKey:(NSString *)kCTFontAttributeName];
//			[mutAttrs setValue:(__bridge id)h1paragraphStyle forKey:(id)kCTParagraphStyleAttributeName];
//            
//			attrs = [mutAttrs copy];
//            
//            NSString* source = [[[currentNode findChildTags:@"span"] objectAtIndex:0] contents];
//            
//            if (source) {
//                //如果带源span,则仅换行
//                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[currentNodeContent stringByAppendingString:@"\r"] attributes:attrs]];
//                
//                CTFontRef sourceSpanFontRef = CTFontCreateWithName((__bridge CFStringRef)self.font,
//                                                           14., NULL);
//                [mutAttrs setValue:(__bridge id)sourceSpanFontRef forKey:(NSString *)kCTFontAttributeName];
//                [mutAttrs setValue:(__bridge id)[UIColor grayColor].CGColor forKey:(NSString *)kCTForegroundColorAttributeName];
//                attrs = [mutAttrs copy];
//                
//                [aString appendAttributedString:[[NSAttributedString alloc] initWithString:source attributes:attrs]];
//                
//                CFRelease(sourceSpanFontRef);
//            } else {
//                //如果不带源span,则成段落，段落默认双换行
//                if (currentNodeContent) [aString appendAttributedString:[[NSAttributedString alloc] initWithString:currentNodeContent attributes:attrs]];
//            }
//            CFRelease(h1FontRef);
//            CFRelease(h1paragraphStyle);
//        }

        if ([[currentNode tagName] isEqualToString:@"p"]) {
            //开始样式设置
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
                                   (__bridge id)fontRef, kCTFontAttributeName,
                                   (id)self.strokeColor.CGColor, (NSString *)kCTStrokeColorAttributeName,
                                   (__bridge id)paragraphStyle,(id)kCTParagraphStyleAttributeName,
                                   (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                                   nil];
            if (currentNodeContent) [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[currentNodeContent stringByAppendingString:@"\r\r"] attributes:attrs]];
            
            // 小标题
            for (HTMLNode *strongNode in [currentNode findChildTags:@"strong"]) {
                CTFontRef strongFontRef = CTFontCreateWithName((__bridge CFStringRef)@"STHeitiSC-Medium",
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
                                         nil];
                
                [self.images addObject:imginfo];
                
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
            CFRelease(fontRef);
            CFRelease(paragraphStyle);
        }
        nodeCount += 1;
    }
    
//        CFRelease(paragraphStyle); 
       

    return (NSAttributedString*)aString;
}

@end
