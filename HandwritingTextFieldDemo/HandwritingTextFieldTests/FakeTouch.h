// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  FakeTouch.h
//  HandwritingTextFieldTests
//
//  Created by Peter Lee on 1/29/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FakeTouch : UITouch

@property (nonatomic)CGPoint location;
@property (nonatomic)CGPoint previousLocation;
@property (nonatomic)NSDate *time;
@property (nonatomic)BOOL endingTouch;

- (instancetype)initWithLocation:(CGPoint)location previousLocation:(CGPoint)previousLocation time:(NSDate *)time;
- (CGPoint)previousLocationInView:(UIView *)view;
- (CGPoint)locationInView:(UIView *)view;

@end
