// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  HandwritingTextFieldTests.m
//  HandwritingTextFieldTests
//
//  Created by Peter Lee on 1/28/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "ViewController.h"
#import "TrackingView.h"
#import "UITextField+Handwriting.h"
#import "FakeTouch.h"
#import "HandwritingRecognizer.h"

const NSTimeInterval kTimeoutInterval = 30.0f;
const NSTimeInterval kTeardownInterval = 5.0f;

@interface HandwritingTextFieldTests : XCTestCase <TrackingViewDelegate> {
    ViewController *_mainViewController;
    UITextField *_textFieldFullscreenView;
    UITextField *_textFieldCustomView;
    UIView *_customHandwritingView;
    UISwitch *_switchControlsVisible;
    
    NSMutableArray *_unreceivedHandwritingResults;
}

@end

@implementation HandwritingTextFieldTests

- (void)setUp
{
    [super setUp];
    
    _mainViewController = (ViewController *)[[[UIApplication sharedApplication] keyWindow] rootViewController];
    
    for (UIView *subview in [[_mainViewController view] subviews]) {
        if ([[subview accessibilityLabel] isEqualToString:@"textfield fullscreen view"]) {
            _textFieldFullscreenView = (UITextField *)subview;
        } else if ([[subview accessibilityLabel] isEqualToString:@"textfield custom view"]) {
            _textFieldCustomView = (UITextField *)subview;
        } else if ([[subview accessibilityLabel] isEqualToString:@"custom handwriting view"]) {
            _customHandwritingView = subview;
        } else if ([[subview accessibilityLabel] isEqualToString:@"switch controls visible"]) {
            _switchControlsVisible = (UISwitch *)subview;
        }
    }
    
    _unreceivedHandwritingResults = nil;
}

- (void)tearDown
{
    [super tearDown];
    
    [[_mainViewController view] endEditing:YES];
    [_textFieldFullscreenView setText:nil];
    [_textFieldCustomView setText:nil];
    
    // pump the run loop to cleanup
    NSDate *timeoutDate = [NSDate dateWithTimeInterval:kTeardownInterval sinceDate:[NSDate date]];
    [[NSRunLoop currentRunLoop] runUntilDate:timeoutDate];
}

- (void)testSetup
{
    XCTAssertTrue([_mainViewController isKindOfClass:[ViewController class]], @"%s - no main view controller", __PRETTY_FUNCTION__);
    XCTAssertTrue([_textFieldFullscreenView isKindOfClass:[UITextField class]], @"%s - no textfield for fullscreen view", __PRETTY_FUNCTION__);
    XCTAssertTrue([_textFieldCustomView isKindOfClass:[UITextField class]], @"%s - no textfield for custom view", __PRETTY_FUNCTION__);
    XCTAssertTrue([_customHandwritingView isKindOfClass:[UIView class]], @"%s - no custom handwriting view", __PRETTY_FUNCTION__);
    XCTAssertTrue([_switchControlsVisible isKindOfClass:[UISwitch class]], @"%s - no switch for toggling control visibility", __PRETTY_FUNCTION__);
}

- (void)testTrackingViewInkPoints
{
    [_textFieldFullscreenView becomeFirstResponder];
    TrackingView *trackingView = [self trackingViewForTextField:_textFieldFullscreenView];
    
    NSArray *fakeTouches = [self fakeTouchesFor_a];
    [self simulateTouchSequence:fakeTouches inView:trackingView completion:^{
        NSArray *trackingViewInkPoints = [trackingView inkPoints];
        XCTAssert([fakeTouches count] == [trackingViewInkPoints count], @"%s - touch sequence generated mismatched ink points", __PRETTY_FUNCTION__);
        
        [self fetchAndCheckHandwritingResults:@[@"a", @"ce", @"Ce"] forTextField:_textFieldFullscreenView];
    }];
}

- (void)testTextfieldFullscreen
{
    [_textFieldFullscreenView becomeFirstResponder];
    TrackingView *trackingView = [self trackingViewForTextField:_textFieldFullscreenView];
    
    NSArray *fakeTouches = [self fakeTouchesFor_cat];
    [self simulateTouchSequence:fakeTouches inView:trackingView completion:^{
        NSArray *trackingViewInkPoints = [trackingView inkPoints];
        XCTAssert([fakeTouches count] == [trackingViewInkPoints count], @"%s - touch sequence generated mismatched ink points", __PRETTY_FUNCTION__);
        
        [self fetchAndCheckHandwritingResults:@[@"cat", @"cart", @"cost"] forTextField:_textFieldFullscreenView];
    }];
}

- (void)testTextfieldCustom
{
    [_textFieldCustomView becomeFirstResponder];
    TrackingView *trackingView = [self trackingViewForTextField:_textFieldCustomView];
    
    NSArray *fakeTouches = [self fakeTouchesFor_dog];
    [self simulateTouchSequence:fakeTouches inView:trackingView completion:^{
        NSArray *trackingViewInkPoints = [trackingView inkPoints];
        XCTAssert([fakeTouches count] == [trackingViewInkPoints count], @"%s - touch sequence generated mismatched ink points", __PRETTY_FUNCTION__);
        
        [self fetchAndCheckHandwritingResults:@[@"dog", @"doy", @"doog"] forTextField:_textFieldCustomView];
    }];

}

- (void)testTrackingViewDelegate
{
    [_textFieldFullscreenView becomeFirstResponder];
    TrackingView *trackingView = [self trackingViewForTextField:_textFieldFullscreenView];
    id<TrackingViewDelegate> delegate = [trackingView delegate];

    [delegate trackingView:trackingView didRecognizeText:@"hello"];
    [delegate trackingView:trackingView didRecognizeText:@"world"];
    XCTAssert([[_textFieldFullscreenView text] isEqualToString:@"hello world"], @"%s - didRecognizeText failure", __PRETTY_FUNCTION__);

    [delegate trackingView:trackingView didReceiveEvent:TrackingViewEventSpace];
    XCTAssert([[_textFieldFullscreenView text] isEqualToString:@"hello world "], @"%s - didReceiveEvent(Space) failure", __PRETTY_FUNCTION__);

    [delegate trackingView:trackingView didReceiveEvent:TrackingViewEventBackspace];
    [delegate trackingView:trackingView didReceiveEvent:TrackingViewEventBackspace];
    XCTAssert([[_textFieldFullscreenView text] isEqualToString:@"hello worl"], @"%s - didReceiveEvent(Backspace) failure", __PRETTY_FUNCTION__);

    [delegate trackingView:trackingView didReceiveEvent:TrackingViewEventClear];
    XCTAssert([[trackingView inkPoints] count] == 0, @"%s - didReceiveEvent(Clear) failure", __PRETTY_FUNCTION__);
}

#pragma mark - helpers

- (TrackingView *)trackingViewForTextField:(UITextField *)textField
{
    TrackingView *trackingView = (TrackingView *)[[[textField handwritingView] subviews] lastObject];
    XCTAssertTrue([trackingView isKindOfClass:[TrackingView class]], @"no tracking view found");
    
    return trackingView;
}

#pragma mark - touch simulation
/*! Simulates a touch sequence with GCD. The timing of the touch events does not translate very accurately to the timing encoded in the fake touches. So the results returned based on these simulated touches should be allowed some variance.
 \param fakeTouches an array of FakeTouch objects to simulate a touch sequence
 */
- (void)simulateTouchSequence:(NSArray *)fakeTouches inView:(TrackingView *)trackingView completion:(void(^)(void))completion
{
    dispatch_group_t simulateTouchGroup = dispatch_group_create();
    
    NSDate *startTime = nil;
    NSTimeInterval delayInSeconds = 0.0f;
    BOOL touchesBegan = YES;
    
    for (FakeTouch *fakeTouch in fakeTouches) {
        BOOL lastTouch = [fakeTouch endingTouch];
        
        // calculate the delay
        if (startTime == nil) {
            startTime = [fakeTouch time];
        } else {
            delayInSeconds = [[fakeTouch time] timeIntervalSinceDate:startTime];
        }

        // dispatch call for each touch
        dispatch_group_enter(simulateTouchGroup);
        
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            if (touchesBegan) {
                [trackingView touchesBegan:[NSSet setWithObject:fakeTouch] withEvent:nil];
            } else {
                [trackingView touchesMoved:[NSSet setWithObject:fakeTouch] withEvent:nil];
            }
            if (lastTouch) {
                [trackingView touchesEnded:[NSSet setWithObject:fakeTouch] withEvent:nil];
            }
            
            dispatch_group_leave(simulateTouchGroup);
        });
        
        if (lastTouch) {
            touchesBegan = YES;
        } else {
            touchesBegan = NO;
        }
    }

    // poll and pump run loop until all touches have finished
    while (dispatch_group_wait(simulateTouchGroup, DISPATCH_TIME_NOW)) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate date]];
    }
    
    completion();

}

- (NSArray *)fakeTouchesFor_a
{
    NSArray *xCoordinates = @[@131, @121, @116, @111, @109, @105, @102, @100, @100, @100, @101, @103, @105, @108, @112, @118, @125, @130, @135, @137, @139, @140, @140, @140, @138, @137, @137, @136, @136, @135, @135, @135, @135, @136, @139, @163, @172, @172];

    NSArray *yCoordinates = @[@158, @158, @160, @162, @165, @171, @176, @182, @186, @188, @189, @190, @190, @190, @190, @190, @187, @184, @182, @180, @175, @172, @169, @168, @165, @164, @163, @163, @161, @161, @160, @162, @165, @170, @177, @195, @199, @198];

    NSArray *timeOffsetsInMilliseconds = @[@0, @20, @36, @52, @69, @85, @102, @119, @135, @152, @169, @185, @202, @219, @235, @252, @269, @286, @303, @320, @352, @369, @402, @419, @452, @469, @486, @519, @552, @569, @586, @669, @686, @702, @719, @775, @802, @869];

    
    NSArray *fakeTouches = [self fakeTouchesForxCoordinates:xCoordinates yCoordinates:yCoordinates timeOffsetsInMilliseconds:timeOffsetsInMilliseconds touchesEndedTimeOffsets:nil];
    
    return fakeTouches;
}

- (NSArray *)fakeTouchesFor_cat
{
    NSArray *xCoordinates = @[@37, @35, @33, @30, @25, @20, @17, @16, @16, @16, @17, @19, @22, @25, @29, @32, @38, @42, @45, @46, @46, @69, @63, @59, @56, @54, @52, @52, @54, @56, @58, @60, @64, @66, @68, @69, @70, @70, @70, @70, @70, @71, @71, @71, @71, @77, @82, @86, @89, @90, @91, @91, @92, @104, @103, @102, @101, @101, @101, @101, @102, @103, @103, @103, @103, @74, @76, @83, @95, @112, @127, @137];

    
    NSArray *yCoordinates = @[@104, @104, @105, @107, @109, @115, @119, @123, @125, @127, @129, @129, @130, @130, @130, @129, @128, @127, @127, @127, @126, @107, @109, @113, @116, @120, @123, @127, @129, @130, @131, @131, @130, @128, @125, @123, @121, @118, @116, @114, @112, @111, @110, @111, @114, @125, @129, @132, @132, @132, @132, @132, @130, @75, @83, @92, @103, @116, @130, @140, @146, @149, @148, @147, @144, @101, @101, @102, @103, @104, @104, @104];
    
    NSArray *timeOffsetsInMilliseconds = @[@0, @19, @35, @52, @71, @102, @119, @135, @152, @169, @185, @202, @219, @235, @252, @269, @285, @302, @318, @336, @368, @792, @818, @836, @852, @868, @886, @902, @919, @936, @952, @969, @985, @1002, @1019, @1036, @1052, @1069, @1086, @1103, @1136, @1169, @1219, @1319, @1336, @1369, @1385, @1402, @1418, @1452, @1469, @1485, @1503, @2007, @2035, @2052, @2069, @2085, @2102, @2118, @2135, @2152, @2235, @2252, @2268, @2552, @2568, @2585, @2602, @2618, @2636, @2669];
    
    NSArray *touchesEndedTimeOffsets = @[@368, @1503, @2268];
    
    NSArray *fakeTouches = [self fakeTouchesForxCoordinates:xCoordinates yCoordinates:yCoordinates timeOffsetsInMilliseconds:timeOffsetsInMilliseconds touchesEndedTimeOffsets:touchesEndedTimeOffsets];
    
    return fakeTouches;
}

- (NSArray *)fakeTouchesFor_dog
{
    NSArray *xCoordinates = @[@44, @45, @45, @46, @46, @47, @48, @48, @49, @49, @49, @49, @48, @47, @44, @40, @35, @31, @24, @22, @22, @21, @22, @24, @29, @38, @46, @51, @54, @56, @56, @56, @56, @56, @69, @67, @67, @70, @76, @81, @86, @89, @91, @91, @90, @88, @83, @77, @72, @72, @72, @126, @118, @115, @112, @110, @109, @109, @110, @113, @117, @124, @131, @137, @141, @143, @143, @143, @142, @142, @142, @142, @142, @141, @139, @136, @133, @129, @123, @115, @105, @94, @83, @78];
    
    NSArray *yCoordinates = @[@23, @31, @37, @44, @50, @57, @62, @65, @66, @65, @65, @61, @59, @57, @55, @54, @53, @53, @53, @55, @57, @59, @64, @67, @70, @72, @72, @72, @72, @71, @70, @70, @69, @69, @57, @62, @65, @68, @70, @71, @71, @70, @67, @64, @61, @57, @54, @52, @51, @51, @52, @51, @51, @51, @53, @55, @58, @62, @64, @67, @69, @70, @70, @68, @66, @63, @58, @55, @54, @54, @55, @56, @58, @64, @73, @82, @89, @96, @99, @100, @100, @97, @93, @90];

    NSArray *timeOffsetsInMilliseconds = @[@0, @19, @39, @58, @74, @91, @108, @125, @141, @208, @224, @252, @269, @286, @303, @319, @336, @353, @386, @403, @419, @436, @469, @486, @502, @519, @536, @553, @569, @586, @603, @619, @636, @652, @1007, @1038, @1057, @1074, @1091, @1107, @1124, @1141, @1157, @1174, @1191, @1208, @1224, @1240, @1269, @1302, @1320, @1847, @1869, @1886, @1902, @1919, @1935, @1952, @1969, @1986, @2002, @2019, @2036, @2053, @2070, @2087, @2120, @2153, @2170, @2185, @2269, @2286, @2302, @2319, @2336, @2352, @2369, @2386, @2402, @2419, @2436, @2453, @2469, @2486];
    
    NSArray *touchesEndedTimeOffsets = @[@652, @1320];
    
    NSArray *fakeTouches = [self fakeTouchesForxCoordinates:xCoordinates yCoordinates:yCoordinates timeOffsetsInMilliseconds:timeOffsetsInMilliseconds touchesEndedTimeOffsets:touchesEndedTimeOffsets];
    
    return fakeTouches;
}


- (NSArray *)fakeTouchesForxCoordinates:(NSArray *)xCoordinates yCoordinates:(NSArray *)yCoordinates timeOffsetsInMilliseconds:(NSArray *)timeOffsetsInMilliseconds touchesEndedTimeOffsets:(NSArray *)touchesEndedTimeOffsets
{
    XCTAssert(([xCoordinates count] == [yCoordinates count]) && ([xCoordinates count] == [timeOffsetsInMilliseconds count]), @"%s - invalid arguments", __PRETTY_FUNCTION__);

    NSMutableArray *fakeTouches = [NSMutableArray array];
    
    BOOL touchesBegan = YES;
    CGPoint previousPoint;
    
    for (NSUInteger i=0; i<[xCoordinates count]; i++) {
        CGPoint point = CGPointMake([[xCoordinates objectAtIndex:i] integerValue], [[yCoordinates objectAtIndex:i] integerValue]);
        NSDate *time = [NSDate dateWithTimeIntervalSince1970:[[timeOffsetsInMilliseconds objectAtIndex:i] integerValue] / 1000.0f];

        if (touchesBegan) {
            previousPoint = point;
        }
        
        FakeTouch *fakeTouch = [[FakeTouch alloc] initWithLocation:point previousLocation:previousPoint time:time];
        [fakeTouches addObject:fakeTouch];
        
        if ([touchesEndedTimeOffsets containsObject:[timeOffsetsInMilliseconds objectAtIndex:i]]) {
            [fakeTouch setEndingTouch:YES];
            touchesBegan = YES;
        } else {
            touchesBegan = NO;
        }
        
        previousPoint = point;
    }
    
    return fakeTouches;
}

#pragma mark - results checking

- (void) fetchAndCheckHandwritingResults:(NSArray *)correctHandwritingResults forTextField:(UITextField *)textField
{
    // temporarily become the TrackingViewDelegate
    TrackingView *trackingView = [self trackingViewForTextField:textField];
    [trackingView setDelegate:self];
    
    _unreceivedHandwritingResults = [NSMutableArray arrayWithArray:correctHandwritingResults];
    [[HandwritingRecognizer sharedRecognizer] fetchHandwritingRecognitionResults];
    
    NSDate *timeoutDate = [NSDate dateWithTimeInterval:kTimeoutInterval sinceDate:[NSDate date]];
    
    // poll and pump run loop until network returns
    while (([[NSDate date] earlierDate:timeoutDate] != timeoutDate) && [_unreceivedHandwritingResults count] > 0) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:timeoutDate];
    }
    
    XCTAssert([_unreceivedHandwritingResults count] == 0, @"%s - did not receive correct handwriting results %@", __PRETTY_FUNCTION__, _unreceivedHandwritingResults);

    // restore the TrackingViewDelegate
    [trackingView setDelegate:(id<TrackingViewDelegate>)textField];
}


#pragma mark - TrackingViewDelegate

- (NSArray *)trackingView:(TrackingView *)trackingView displayHandwritingResults:(NSArray *)results
{
    [_unreceivedHandwritingResults removeObjectsInArray:results];
    
    return results;
}

- (void)trackingView:(TrackingView *)trackingView didRecognizeText:(NSString *)text
{
}

- (void)trackingView:(TrackingView *)trackingView didReceiveEvent:(TrackingViewEvent)event
{
}

@end
