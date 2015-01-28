//
//  FingerboardUI.m
//  Fingerboard
//
//  Created by Trijeet Mukhopadhyay on 1/26/15.
//  Copyright (c) 2015 Trijeet Mukhopadhyay. All rights reserved.
//

#import "FingerboardUI.h"
#import "Globals.h"

@implementation FingerboardUI


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    CGFloat screenWidth = Globals::fingerboardWidth = self.bounds.size.width;
    CGFloat screenHeight = Globals::fingerboardHeight = self.bounds.size.height;
    
    int scaleLength = Globals::scale.size();
    
    UIColor *lblue1 = [UIColor colorWithRed:48.0f/255.0f green:57.0f/255.0f blue:92.0f/255.0f alpha:1.0f];
    UIColor *lblue2 = [UIColor colorWithRed:74.0f/255.0f green:100.0f/255.0f blue:145.0f/255.0f alpha:1.0f];
    UIColor *dblue = [UIColor colorWithRed:26.0f/255.0f green:31.0f/255.0f blue:43.0f/255.0f alpha:1.0f];
    
    // Drawing code
    for (int i = 0; i < scaleLength; i++) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 10.0);
        CGContextSetStrokeColorWithColor(context,
                                         lblue2.CGColor);
        CGRect rectangle = CGRectMake(0, (screenHeight / scaleLength) * i, screenWidth / 2, screenHeight / scaleLength);
        CGContextAddRect(context, rectangle);
        CGContextStrokePath(context);
        CGContextSetFillColorWithColor(context,
                                       dblue.CGColor);
        CGContextFillRect(context, rectangle);
    }
    for (int i = 0; i < scaleLength; i++) {
        CGContextRef context = UIGraphicsGetCurrentContext();
        CGContextSetLineWidth(context, 10.0);
        CGContextSetStrokeColorWithColor(context,
                                         dblue.CGColor);
        CGRect rectangle = CGRectMake(screenWidth / 2, (screenHeight / scaleLength) * i, screenWidth / 2, screenHeight / scaleLength);
        CGContextAddRect(context, rectangle);
        CGContextStrokePath(context);
        CGContextSetFillColorWithColor(context,
                                       lblue1.CGColor);
        CGContextFillRect(context, rectangle);
    }
}


@end
