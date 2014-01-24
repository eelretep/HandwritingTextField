//
//  InkPoint.m
//  HandwritingTextField
//
//  Created by Peter Lee on 12/20/13.
//

#import "InkPoint.h"

@implementation InkPoint

- (id)initWithPoint:(CGPoint)point
{
    self = [super init];
    if (self != nil) {
        _point = point;
        _time = [NSDate date];
    }
    
    return self;
}

- (NSString *)debugDescription
{
    return ([NSString stringWithFormat:@"%f, %f, %@", _point.x, _point.y, _time]);
}

@end
