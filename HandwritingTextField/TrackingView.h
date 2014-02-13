// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  TrackingView.h
//  HandwritingTextField
//
//  Created by Peter Lee on 1/17/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TrackingViewDelegate;
extern const CGFloat kTrackingViewMinControlHeight;

typedef enum {
    TrackingViewEventDone = 0,
    TrackingViewEventClear,
    TrackingViewEventSpace,
    TrackingViewEventBackspace,
    TrackingViewEventShowKeyboard,
} TrackingViewEvent;

@interface TrackingView : UIView

@property (nonatomic) BOOL controlsVisible;
@property (nonatomic) UIEdgeInsets controlsEdgeInsets;
@property (nonatomic, weak) id<TrackingViewDelegate>delegate;

@property (nonatomic, readonly) UIButton *doneButton;
@property (nonatomic, readonly) UIButton *showKeyboardButton;
@property (nonatomic, readonly) UIButton *clearButton;
@property (nonatomic, readonly) UIButton *backspaceKey;
@property (nonatomic, readonly) UIButton *spaceKey;

- (NSArray *)inkPoints;
- (void)clearInk;

@end


@protocol TrackingViewDelegate <NSObject>

- (void)trackingView:(TrackingView *)trackingView didRecognizeText:(NSString *)text;
- (void)trackingView:(TrackingView *)trackingView didReceiveEvent:(TrackingViewEvent)event;

@optional
- (NSArray *)trackingView:(TrackingView *)trackingView displayHandwritingResults:(NSArray *)results;

@end
