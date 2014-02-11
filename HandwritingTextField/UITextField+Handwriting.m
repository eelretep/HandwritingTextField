//
//  UITextField+Handwriting.h
//  HandwritingTextField
//
//  Created by Peter Lee on 12/30/13.
//
//

#import <objc/runtime.h>
#import "UITextField+Handwriting.h"
#import "InkPoint.h"
#import "HandwritingRecognizer.h"
#import "TrackingView.h"

static void const * kTextFieldHandwritingEnabledKey = &kTextFieldHandwritingEnabledKey;
static void const * kTextFieldHandwritingControlsVisibleKey = &kTextFieldHandwritingControlsVisibleKey;
static void const * kTextFieldHandwritingViewKey = &kTextFieldHandwritingViewKey;
static void const * kTextFieldTrackingViewKey = &kTextFieldTrackingViewKey;

@implementation UITextField (Handwriting)

#pragma mark - category properties

- (void)setHandwritingEnabled:(BOOL)handwritingEnabled
{
    NSNumber *number = [NSNumber numberWithBool:handwritingEnabled];
    objc_setAssociatedObject(self, kTextFieldHandwritingEnabledKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)handwritingEnabled
{
    NSNumber *number = objc_getAssociatedObject(self, kTextFieldHandwritingEnabledKey);
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

- (void)setHandwritingControlsVisible:(BOOL)handwritingControlsVisible
{
    NSNumber *number = [NSNumber numberWithBool:handwritingControlsVisible];
    objc_setAssociatedObject(self, kTextFieldHandwritingControlsVisibleKey, number, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    TrackingView *trackingView = [self trackingView];
    if ([self trackingView] != nil) {
        [trackingView setControlsVisible:handwritingControlsVisible];
    }
}

- (BOOL)handwritingControlsVisible
{
    NSNumber *number = objc_getAssociatedObject(self, kTextFieldHandwritingControlsVisibleKey);
    return [number boolValue];
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
    if ([self handwritingEnabled]) {
        // create the overlay tracking
        if ([self trackingView] == nil) {
            TrackingView *trackingView = [[HandwritingRecognizer sharedRecognizer] overlayTrackingViewInView:[self handwritingView]];
            [trackingView setDelegate:(id<TrackingViewDelegate>)self];
            
            [self setTrackingView:trackingView];

        }
        
        // start tracking
        TrackingView *trackingView = [self trackingView];
        if ([[HandwritingRecognizer sharedRecognizer] startTrackingHandwriting:trackingView]) {
            if ([self handwritingControlsVisible]) {
                [trackingView setControlsVisible:YES];
            }

            // set a blank input view to replace the default keyboard
            [self setInputView:[[UIView alloc] init]];
        }
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
    [[HandwritingRecognizer sharedRecognizer] clearHandwriting:[self trackingView]];
}

#pragma mark - TrackingViewDelegate 

- (void)trackingView:(TrackingView *)trackingView didRecognizeText:(NSString *)text
{
    if ([text length] > 0) {
        NSString *currentText = [self text];
        UITextRange *selectedRange = [self selectedTextRange];
        
        // if appending to existing text, insert a space
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

