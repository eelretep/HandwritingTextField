// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  UITextField+Handwriting.h
//  HandwritingTextField
//
//  Created by Peter Lee on 12/30/13.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITextField (Handwriting)

@property (nonatomic) BOOL handwritingControlsVisible; // cancel, space, backspace, keyboard, etc...
@property (nonatomic) UIView *handwritingView; // view where handwriting tracking is overlayed

- (void)beginHandwriting;
- (void)endHandwriting;
- (void)clearHandwriting;

@end
