// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  InkPoint.m
//  HandwritingTextField
//
//  Created by Peter Lee on 12/20/13.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
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
