//
//  Picture.h
//  DaPengTi2
//
//  Created by  on 12-7-2.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Issue;

@interface Picture : NSManagedObject

@property (nonatomic, retain) NSNumber * pictureID;
@property (nonatomic, retain) NSNumber * width;
@property (nonatomic, retain) NSNumber * height;
@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * url;
@property (nonatomic, retain) Issue *issue;

@end
