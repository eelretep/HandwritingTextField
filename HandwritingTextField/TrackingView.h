//
//  TrackingView.h
//  HandwritingTextField
//
//  Created by Peter Lee on 1/17/14.
//  Copyright (c) 2014 Peter Lee. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TrackingViewDelegate;

typedef enum {
    TrackingViewEventDone = 0,
    TrackingViewEventSpace = 1,
    TrackingViewEventBackspace = 2,
    TrackingViewEventShowKeyboard = 3,
} TrackingViewEvent;


@interface TrackingView : UIView

@property (nonatomic) BOOL controlsVisible;
@property (nonatomic) UIEdgeInsets controlsEdgeInsets;
@property (nonatomic, weak) id<TrackingViewDelegate>delegate;

@property (nonatomic, readonly) UIButton *doneButton;
@property (nonatomic, readonly) UIButton *showKeyboardButton;
@property (nonatomic, readonly) UIButton *backspaceKey;
@property (nonatomic, readonly) UIButton *spaceKey;

- (NSArray *)inkPoints;
- (void)clearInk;

@end





@protocol TrackingViewDelegate

- (void)trackingView:(TrackingView *)trackingView didRecognizeText:(NSString *)text;
- (void)trackingView:(TrackingView *)trackingView didReceiveEvent:(TrackingViewEvent)event;

@end
