// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  InkPoint.h
//  HandwritingTextField
//
//  Created by Peter Lee on 12/20/13.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface InkPoint : NSObject

- (id)initWithPoint:(CGPoint)point;

@property (nonatomic, readonly)CGPoint point;
@property (nonatomic, readonly)NSDate *time;

@end
