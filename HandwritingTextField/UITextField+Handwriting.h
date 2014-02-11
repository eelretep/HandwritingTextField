//
//  UITextField+Handwriting.h
//  HandwritingTextField
//
//  Created by Peter Lee on 12/30/13.
//
//

#import <UIKit/UIKit.h>

@interface UITextField (Handwriting)

@property (nonatomic) BOOL handwritingEnabled;
@property (nonatomic) BOOL handwritingControlsVisible;
@property (nonatomic) UIView *handwritingView;

- (void)beginHandwriting;
- (void)endHandwriting;
- (void)clearHandwriting;

@end
