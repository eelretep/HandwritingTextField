//
//  FakeTouch.h
//  HandwritingTextFieldDemo
//
//  Created by Peter Lee on 1/29/14.
//  Copyright (c) 2014 Peter Lee. All rights reserved.
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
