//
//  InkPoint.h
//  HandwritingTextField
//
//  Created by Peter Lee on 12/20/13.
//

#import <Foundation/Foundation.h>

@interface InkPoint : NSObject

- (id)initWithPoint:(CGPoint)point;

@property (nonatomic, readonly)CGPoint point;
@property (nonatomic, readonly)NSDate *time;

@end
