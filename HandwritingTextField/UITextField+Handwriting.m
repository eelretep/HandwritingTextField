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

#import <objc/runtime.h>
#import "UITextField+Handwriting.h"
#import "InkPoint.h"
#import "HandwritingRecognizer.h"
#import "TrackingView.h"

static void const * kTextFieldHandwritingControlsVisibleKey = &kTextFieldHandwritingControlsVisibleKey;
static void const * kTextFieldHandwritingViewKey = &kTextFieldHandwritingViewKey;
static void const * kTextFieldTrackingViewKey = &kTextFieldTrackingViewKey;

@implementation UITextField (Handwriting)

#pragma mark - category properties

- (void)setHandwritingControlsVisible:(BOOL)handwritingControlsVisible
{
    NSNumber *number = [NSNumber numberWithBool:handwritingControlsVisible];
    objc_setAssociatedObject(self, kTextFieldHandwritingControlsVisibleKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    TrackingView *trackingView = [self trackingView];
    if (trackingView != nil) {
        [trackingView setControlsVisible:handwritingControlsVisible];
        [[HandwritingRecognizer sharedRecognizer] layoutControls:trackingView];
    }
}

- (BOOL)handwritingControlsVisible
{
    NSNumber *number = objc_getAssociatedObject(self, kTextFieldHandwritingControlsVisibleKey);
    return [number boolValue];
}

- (void)setHandwritingView:(UIView *)view
{
    objc_setAssociatedObject(self, kTextFieldHandwritingViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)handwritingView
{
    return objc_getAssociatedObject(self, kTextFieldHandwritingViewKey);
}

- (void)setTrackingView:(TrackingView *)view
{
    objc_setAssociatedObject(self, kTextFieldTrackingViewKey, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (TrackingView *)trackingView
{
    return objc_getAssociatedObject(self, kTextFieldTrackingViewKey);
}


#pragma mark - handwriting

- (void)beginHandwriting
{
    // overlay a handwriting tracking view
    if ([self trackingView] == nil) {
        TrackingView *trackingView = [[HandwritingRecognizer sharedRecognizer] overlayTrackingViewInView:[self handwritingView]];
        [trackingView setDelegate:(id<TrackingViewDelegate>)self];
        
        [self setTrackingView:trackingView];
    }

    // control visibility
    TrackingView *trackingView = [self trackingView];
    CGRect windowBounds = [[trackingView window] bounds];
    windowBounds = [trackingView convertRect:windowBounds fromView:[trackingView window]];
    if (CGRectEqualToRect([trackingView bounds], windowBounds)) {
       
        // when tracking in fullscreen, don't obscure the status bar
        if ([[UIApplication sharedApplication] isStatusBarHidden] == NO) {
            UIEdgeInsets edgeInsets = [trackingView controlsEdgeInsets];
            CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
            edgeInsets.top = MIN(statusBarSize.width, statusBarSize.height);
            [trackingView setControlsEdgeInsets:edgeInsets];
        }
        
        // controls are required or else the user cannot end the handwriting
        [trackingView setControlsVisible:YES];

    } else {
        [trackingView setControlsVisible:[self handwritingControlsVisible]];
    }
    
    // start tracking
    if ([[HandwritingRecognizer sharedRecognizer] startTrackingHandwriting:trackingView]) {
        // blank input view prevents the standard system keyboard from appearing
        [self setInputView:[[UIView alloc] init]];
    }
}

- (void)endHandwriting
{
    TrackingView *trackingView = [self trackingView];
    if (trackingView != nil) {
        [[HandwritingRecognizer sharedRecognizer] stopTrackingHandwriting:trackingView];
        [self setTrackingView:nil];
    }
    [self setInputView:nil];
}

- (void)clearHandwriting
{
    [[HandwritingRecognizer sharedRecognizer] clear:[self trackingView]];
}

#pragma mark - TrackingViewDelegate 

- (void)trackingView:(TrackingView *)trackingView didRecognizeText:(NSString *)text
{
    if ([text length] > 0) {
        NSString *currentText = [self text];
        UITextRange *selectedRange = [self selectedTextRange];
        
        // insert a space when appending to the end of existing text,
        if ([currentText length] > 0 && [selectedRange isEmpty]) {
            NSComparisonResult comparisionResult = [self comparePosition:[selectedRange end] toPosition:[self endOfDocument]];
            if (comparisionResult == NSOrderedSame) {
                text = [NSString stringWithFormat:@" %@", text];
                
            }
        }
        [self insertText:text];
    }
}

- (void)trackingView:(TrackingView *)trackingView didReceiveEvent:(TrackingViewEvent)event
{
    switch (event) {
        case TrackingViewEventDone:
            [[HandwritingRecognizer sharedRecognizer] stopTrackingHandwriting:trackingView];
            [self resignFirstResponder];
            break;

        case TrackingViewEventClear:
            [[HandwritingRecognizer sharedRecognizer] cancelFetchHandwritingRecognitionResults];
            [self clearHandwriting];
            break;
            
        case TrackingViewEventSpace:
            [self insertText:@" "];
            break;
            
        case TrackingViewEventBackspace:
            [self deleteBackward];
            [self clearHandwriting];
            break;
            
        case TrackingViewEventShowKeyboard:
            [self endHandwriting];
            [self reloadInputViews];            
            break;
    }
}
@end

