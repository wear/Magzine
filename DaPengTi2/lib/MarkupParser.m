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
//static void deallocCallback( void* ref ){
//    (__bridge id)ref;
//}
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
@synthesize images;

-(id)init
{
    self = [super init];
    if (self) {
        self.font = @"STHeitiTC-Light";
        self.color = [UIColor blackColor];
        self.strokeColor = [UIColor whiteColor];
        self.strokeWidth = 0.0;
        self.images = [NSMutableArray array];
    }
    return self;
}

-(NSAttributedString*)attrStringFromMarkup:(NSString*)markup
{

	NSMutableAttributedString* aString = [[NSMutableAttributedString alloc] initWithString:@""]; 
    NSError *error = nil;
    
    HTMLParser *parser = [[HTMLParser alloc] initWithString:markup error:&error];
    
    if (error) {
        NSLog(@"Error: %@", error);
        return nil;
    }
    
    HTMLNode *bodyNode = [parser body];
    
    NSArray *pNodes = [bodyNode findChildTags:@"p"];
    
    for (HTMLNode *pNode in pNodes) {
        NSString *tagContent = [pNode contents];
		if (tagContent) {
            CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)self.font,
                                                     21.0f, NULL);
            NSDictionary* attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                   (id)self.color.CGColor, kCTForegroundColorAttributeName,
                                   (__bridge id)fontRef, kCTFontAttributeName,
                                   (id)self.strokeColor.CGColor, (NSString *) kCTStrokeColorAttributeName,
                                   (id)[NSNumber numberWithFloat: self.strokeWidth], (NSString *)kCTStrokeWidthAttributeName,
                                   nil];
            [aString appendAttributedString:[[NSAttributedString alloc] initWithString:[tagContent stringByAppendingString:@"\r\r"] attributes:attrs]];
            CFRelease(fontRef);
        }
        
        NSArray* imageNodes =  [pNode findChildTags:@"img"];
        
        for (HTMLNode *imgNode in imageNodes) {
            NSDictionary* imginfo = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [imgNode getAttributeNamed:@"width"], @"width",
                                     [imgNode getAttributeNamed:@"height"], @"height",
                                     [NSNumber numberWithInteger:[aString length]],@"location",
                                     [imgNode getAttributeNamed:@"src"],@"src",
                                     nil];
            
            [self.images addObject:imginfo];
            
            //render empty space for drawing the image in the text //1
            CTRunDelegateCallbacks callbacks;
            callbacks.version = kCTRunDelegateVersion1;
            callbacks.getAscent = ascentCallback;
            callbacks.getDescent = descentCallback;
            callbacks.getWidth = widthCallback;
            //                callbacks.dealloc = deallocCallback;
            
            NSDictionary* imgAttr = [NSDictionary dictionaryWithObjectsAndKeys: //2
                                     [imgNode getAttributeNamed:@"width"], @"width",
                                     [imgNode getAttributeNamed:@"height"], @"height",
                                     nil];
            
            CTRunDelegateRef delegate = CTRunDelegateCreate(&callbacks,(__bridge void*)imgAttr); //3
            NSDictionary *attrDictionaryDelegate = [NSDictionary dictionaryWithObjectsAndKeys:
                                                    //set the delegate
                                                    (__bridge id)delegate, (NSString*)kCTRunDelegateAttributeName,
                                                    nil];
            
            //add a space to the text so that it can call the delegate
            [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@" " attributes:attrDictionaryDelegate]];
            [aString appendAttributedString:[[NSAttributedString alloc] initWithString:@"\r\r"]]; 
        }
        
    }

    return (NSAttributedString*)aString;
}
@end
