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
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [[_mainViewController view] endEditing:YES];
    [_textFieldFullscreenView setText:nil];
    [_textFieldCustomView setText:nil];
    
    // run loop cleanup
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
    
    NSArray *fakeTouches = [self fakeiPadTouchesFor_a];
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
    
    NSArray *fakeTouches = [self fakeiPadTouchesFor_apple];
    [self simulateTouchSequence:fakeTouches inView:trackingView completion:^{
        NSArray *trackingViewInkPoints = [trackingView inkPoints];
        XCTAssert([fakeTouches count] == [trackingViewInkPoints count], @"%s - touch sequence generated mismatched ink points", __PRETTY_FUNCTION__);
        
        [self fetchAndCheckHandwritingResults:@[@"apple", @"applie", @"applle"] forTextField:_textFieldFullscreenView];
    }];
}

- (void)testTextfieldCustom
{
    XCTAssert(NO, @"%s", __PRETTY_FUNCTION__);
}

- (void)testTrackingViewDelegate
{
    XCTAssert(NO, @"%s", __PRETTY_FUNCTION__);
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

- (NSArray *)fakeiPadTouchesFor_a
{
    NSArray *xCoordinates = @[@131, @121, @116, @111, @109, @105, @102, @100, @100, @100, @101, @103, @105, @108, @112, @118, @125, @130, @135, @137, @139, @140, @140, @140, @138, @137, @137, @136, @136, @135, @135, @135, @135, @136, @139, @163, @172, @172];

    NSArray *yCoordinates = @[@758, @758, @760, @762, @765, @771, @776, @782, @786, @788, @789, @790, @790, @790, @790, @790, @787, @784, @782, @780, @775, @772, @769, @768, @765, @764, @763, @763, @761, @761, @760, @762, @765, @770, @777, @795, @799, @798];

    NSArray *timeOffsetsInMilliseconds = @[@0, @20, @36, @52, @69, @85, @102, @119, @135, @152, @169, @185, @202, @219, @235, @252, @269, @286, @303, @320, @352, @369, @402, @419, @452, @469, @486, @519, @552, @569, @586, @669, @686, @702, @719, @775, @802, @869];

    
    NSArray *fakeTouches = [self fakeTouchesForxCoordinates:xCoordinates yCoordinates:yCoordinates timeOffsetsInMilliseconds:timeOffsetsInMilliseconds touchesEndedTimeOffsets:nil];
    
    return fakeTouches;
}

- (NSArray *)fakeiPadTouchesFor_apple
{
    NSArray *xCoordinates = @[@148, @146, @144, @137, @130, @121, @114, @107, @103, @100, @100, @100, @102, @106, @110, @117, @125, @132, @140, @149, @153, @154, @156, @156, @156, @156, @156, @156, @154, @153,@152, @151, @149, @149,@149, @149, @149, @149, @149, @149, @151, @153, @158, @162, @164, @171, @178, @185, @190, @193, @195, @196, @223, @223, @223, @223, @221, @221, @221, @221, @221, @221, @221, @221, @221, @221, @221, @221, @221, @223, @226, @228, @231, @234, @237, @238, @239, @242, @246, @247, @248, @248, @248, @247, @244, @240, @235, @230, @223, @222, @265, @265, @265, @265, @262, @262, @260, @258, @257, @257, @257, @258, @259, @265, @272, @279, @284, @290, @294, @297, @299, @301, @304, @305, @305, @304, @299, @294, @286, @280, @274, @272, @331, @331, @330, @330, @330, @330, @330, @330, @330, @330, @329, @329, @329, @329, @329, @329, @351, @352, @356, @363, @373, @383, @390, @395, @395, @395, @394, @391, @388, @383, @376, @373, @369, @366, @364, @361, @358, @357, @357, @355, @355, @354, @354, @354, @354, @354, @357, @358, @362, @368, @376, @387, @397, @404, @412, @421, @428, @435, @439, @441];

    
    NSArray *yCoordinates = @[@727, @727, @727, @728, @731, @735, @739, @745, @750, @754, @758, @761, @765, @768, @770, @772, @772, @772, @772, @770, @765, @764, @760, @756, @753, @749, @746, @742, @739, @738, @735, @733, @731, @729, @728, @727, @726, @725, @724, @725, @726, @733, @741, @751, @759, @768, @775, @781, @783, @785, @785, @785, @728, @731, @738, @749, @765, @783, @799, @809, @816, @823, @825, @824, @821, @814, @802, @791, @779, @765, @754, @745, @740, @736, @733, @732, @732, @732, @732, @733, @735, @738, @743, @747, @751, @753, @756, @757, @758, @759, @734, @737, @746, @761, @777, @791, @800, @805, @807, @806, @798, @787, @774, @762, @752, @745, @739, @737, @734, @734, @734, @735, @739, @744, @749, @751, @756, @757, @760, @760, @761, @761, @659, @675, @684, @693, @703, @712, @719, @728, @733, @737, @741, @743, @745, @747, @752, @753, @744, @744, @744, @744, @742, @741, @738, @734, @730, @729, @727, @727, @726, @726, @726, @726, @727, @729, @730, @733, @735, @737, @740, @741, @744, @745, @747, @750, @752, @753, @754, @756, @757, @760, @763, @767, @768, @771, @773, @773, @774, @774, @774, @774];
    
    NSArray *timeOffsetsInMilliseconds = @[@0, @37, @53, @70, @87, @103, @120, @137, @154, @170, @187, @203, @220, @236, @254, @270, @287, @304, @320, @337, @353, @370, @387, @404, @420, @437, @453, @470, @487, @503, @520, @537, @570, @587, @604, @637, @671, @703, @737, @804, @820, @836, @853, @871, @887, @903, @920, @937, @953, @970, @987, @1087, @1416, @1437, @1453, @1470, @1487, @1503, @1520, @1537, @1555, @1588, @1621, @1671, @1687, @1704, @1721, @1737, @1753, @1770, @1786, @1804, @1820, @1837, @1853, @1870, @1887, @1903, @1937, @1953, @1970, @1986, @2003, @2020, @2037, @2053, @2070, @2087, @2121, @2204, @2496, @2520, @2537, @2553, @2570, @2587, @2603, @2620, @2637, @2703, @2720, @2736, @2753, @2770, @2787, @2803, @2820, @2837, @2853, @2871, @2887, @2903, @2920, @2936, @2953, @2970, @2986, @3003, @3020, @3037, @3053, @3070, @3496, @3520, @3536, @3553, @3570, @3586, @3603, @3620, @3637, @3653, @3670, @3686, @3703, @3720, @3736, @3753, @4256, @4286, @4303, @4320, @4337, @4353, @4370, @4404, @4436, @4453, @4469, @4486, @4503, @4519, @4536, @4553, @4570, @4587, @4603, @4620, @4636, @4653, @4670, @4686, @4703, @4720, @4737, @4753, @4769, @4787, @4803, @4820, @4836, @4853, @4870, @4886, @4903, @4919, @4936, @4953, @4970, @4986, @5003, @5070];
    
    NSArray *touchesEndedTimeOffsets = @[@1087, @2204, @3070, @3753, @5070];
    
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
