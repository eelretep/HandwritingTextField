//
//  FakeTouch.m
//  HandwritingTextFieldDemo
//
//  Created by Peter Lee on 1/29/14.
//  Copyright (c) 2014 Peter Lee. All rights reserved.
//

#import "FakeTouch.h"

@implementation FakeTouch

- (instancetype)initWithLocation:(CGPoint)location previousLocation:(CGPoint)previousLocation time:(NSDate *)time
{
    self = [super init];
    
    if (self != nil) {
        _location = location;
        _previousLocation = previousLocation;
        _time = time;
    }
    
    return self;
}

- (CGPoint)previousLocationInView:(UIView *)view
{
    return _previousLocation;
}

- (CGPoint)locationInView:(UIView *)view
{
    return _location;
}


@end
