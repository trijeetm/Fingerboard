//
//  FingerboardUI.m
//  Fingerboard
//
//  Created by Trijeet Mukhopadhyay on 1/26/15.
//  Copyright (c) 2015 Trijeet Mukhopadhyay. All rights reserved.
//

#import "FingerboardUI.h"

@implementation FingerboardUI


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    CGFloat screenHeight = screenRect.size.height;
    
    int scaleLength = 8;
    
    // Drawing code
    for (int i = 0; i < scaleLength; i++) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context,
                                         [UIColor blueColor].CGColor);
        CGRect rectangle = CGRectMake(0, (screenHeight / scaleLength) * i, screenWidth / 2, screenHeight / scaleLength);
        CGContextAddRect(context, rectangle);
        CGContextStrokePath(context);
        CGContextSetFillColorWithColor(context,
                                       [UIColor redColor].CGColor);
        CGContextFillRect(context, rectangle);
    }
    for (int i = 0; i < scaleLength; i++) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 2.0);
        CGContextSetStrokeColorWithColor(context,
                                         [UIColor redColor].CGColor);
        CGRect rectangle = CGRectMake(screenWidth / 2, (screenHeight / scaleLength) * i, screenWidth / 2, screenHeight / scaleLength);
        CGContextAddRect(context, rectangle);
        CGContextStrokePath(context);
        CGContextSetFillColorWithColor(context,
                                       [UIColor blueColor].CGColor);
        CGContextFillRect(context, rectangle);
    }
}


@end
