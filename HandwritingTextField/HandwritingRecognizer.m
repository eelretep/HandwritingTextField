// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  HandwritingRecognizer.m
//  HandwritingTextField
//
//  Created by Peter Lee on 1/16/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import "HandwritingRecognizer.h"
#import "TrackingView.h"
#import "InkPoint.h"

#define TAG_SEGMENTEDCONTROL            1000
#define TAG_SCROLLVIEW                  1001

#define HANDWRITING_LINECOLOR           [UIColor blackColor]
#define HANDWRITING_LINEWIDTH           5.0f

const NSTimeInterval kDelayBeforeFetch  = 1.0;
NSString * const kNoResultsText         = @"No Handwriting Results";

@interface HandwritingRecognizer() {
    TrackingView *_activeTrackingView;
    
    NSURLSessionUploadTask *_handwritingRecognitionTask;
}

@end

@implementation HandwritingRecognizer

#pragma mark - lifecycle

+ (instancetype)sharedRecognizer
{
    static dispatch_once_t pred;
    static HandwritingRecognizer *shared = nil;
    dispatch_once(&pred, ^{
        shared = [[HandwritingRecognizer alloc] init];
    });
    
    return shared;
}

- (id) init
{
    self = [super init];
    
	if (self != nil) {
        [self setLineColor:HANDWRITING_LINECOLOR];
        [self setLineWidth:HANDWRITING_LINEWIDTH];
    }
    
    return self;
}

#pragma mark - tracking

- (TrackingView *)overlayTrackingViewInView:(UIView *)view
{
    TrackingView *trackingView = nil;
 
    if (view != nil) {
        trackingView = [[TrackingView alloc] initWithFrame:[view bounds]];
        [view addSubview:trackingView];
    }
    
    return trackingView;
}


- (BOOL)startTrackingHandwriting:(TrackingView *)trackingView
{
    BOOL success = NO;
    _activeTrackingView = trackingView;

    if (_activeTrackingView != nil) {
        [self clear:_activeTrackingView];
        
        success = YES;
    }
    
    return success;
}

- (void)stopTrackingHandwriting:(TrackingView *)trackingView
{
    [trackingView removeFromSuperview];
    
    if (_activeTrackingView == trackingView) {
        _activeTrackingView = nil;
    }
}

#pragma mark - control behaviors

- (void)clear:(TrackingView *)trackingView {
    
    [trackingView clearInk];
    [self clearHandwritingResults:trackingView placedholderText:kNoResultsText];
    
    if (_activeTrackingView == trackingView) {
        [self cancelFetchHandwritingRecognitionResults];
    }
}

- (void)layoutControls:(TrackingView *)trackingView
{
    UIScrollView *resultsScrollView = [self resultsScrollView:trackingView];
    if (trackingView && resultsScrollView) {
        [self sizeResultsScrollView:resultsScrollView toFitTrackingView:trackingView];
    }
}

#pragma mark - handwriting recognition

- (void)fetchHandwritingRecognitionResultsAfterDelay
{
    [self cancelFetchHandwritingRecognitionResults];
    
    [self performSelector:@selector(fetchHandwritingRecognitionResults) withObject:nil afterDelay:kDelayBeforeFetch];
}

- (void)cancelFetchHandwritingRecognitionResults
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fetchHandwritingRecognitionResults) object:nil];
    
    [_handwritingRecognitionTask cancel];
    _handwritingRecognitionTask = nil;
}

- (void)fetchHandwritingRecognitionResults
{
    NSURL *url = [NSURL URLWithString:@"https://www.google.com/inputtools/request?ime=handwriting&app=mobilesearch&cs=1&oe=UTF-8"];
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:url];
    [urlRequest setHTTPMethod:@"POST"];
    [urlRequest addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSDictionary *requestJSON = [self JSONObjectForInkPoints:[_activeTrackingView inkPoints]];
    NSData *inkData = [NSJSONSerialization dataWithJSONObject:requestJSON options:0 error:NULL];
    //NSLog(@"%@", [[NSString alloc] initWithData:inkData encoding:NSUTF8StringEncoding]);
    
    _handwritingRecognitionTask = [session uploadTaskWithRequest:urlRequest fromData:inkData completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error != nil) {
            NSLog(@"requestOCRForInkPoints error - %@", error);
        } else {
            NSArray *responseJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
            NSString *statusString = [responseJSON objectAtIndex:0];
            if ([statusString isEqualToString:@"SUCCESS"]) {
                NSArray *resultsArray = [[[responseJSON lastObject] lastObject] lastObject];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSArray *resultsToDisplay = resultsArray;
                    
                    if ([[_activeTrackingView delegate] respondsToSelector:@selector(trackingView:displayHandwritingResults:)]) {
                        resultsToDisplay = [[_activeTrackingView delegate] trackingView:_activeTrackingView displayHandwritingResults:resultsArray];
                    }
                    
                    [self update:_activeTrackingView withHandwritingResults:resultsToDisplay];
                });
            }
            
            //NSLog(@"requestOCRForInkPoints (%@)  %@ \n\n--------------->\n\n %@", urlRequest, requestJSON, responseJSON);
        }
    }];
    [_handwritingRecognitionTask resume];
}

- (NSDictionary *)JSONObjectForInkPoints:(NSArray *)inkPoints
{
    NSMutableDictionary *JSONObject = [NSMutableDictionary dictionary];
    [JSONObject setObject:@"Mozilla/5.0 (iPad; CPU OS 7_0_3 like Mac OS X) AppleWebKit/537.51.1 (KHTML, like Gecko) Version/7.0 Mobile/11B508 Safari/9537.53 ApiKey/1.290" forKey:@"device"];
    [JSONObject setObject:@"enable_pre_space" forKey:@"options"];
    
    NSMutableDictionary *request = [NSMutableDictionary dictionary];
    CGRect bounds = [_activeTrackingView bounds];
    [request setObject:@{@"writing_area_width":[NSNumber numberWithInt:bounds.size.width], @"writing_area_height":[NSNumber numberWithInt:bounds.size.height]} forKey:@"writing_guide"];
    [request setObject:@"en" forKey:@"language"];
    
    NSMutableArray *xCoordinates = [NSMutableArray array];
    NSMutableArray *yCoordinates = [NSMutableArray array];
    NSMutableArray *times = [NSMutableArray array];
    NSDate *startTime = nil;
    
    for (InkPoint *inkPoint in inkPoints) {
        if (startTime == nil) {
            startTime = [inkPoint time];
        }
        
        [xCoordinates addObject:[NSNumber numberWithInt:inkPoint.point.x]];
        [yCoordinates addObject:[NSNumber numberWithInt:inkPoint.point.y]];
        NSTimeInterval inkPointTimeOffset = [[inkPoint time] timeIntervalSinceDate:startTime];
        int timeOffsetMs = inkPointTimeOffset * 1000;
        [times addObject:[NSNumber numberWithInt:timeOffsetMs]];
    }
    
    [request setObject:@[@[xCoordinates, yCoordinates, times]] forKey:@"ink"];
    [JSONObject setObject:@[request] forKey:@"requests"];
    
    //NSLog(@"JSONObjectForInkPoints - xCoordinates %@", [xCoordinates componentsJoinedByString:@", @"]);
    //NSLog(@"JSONObjectForInkPoints - yCoordinates %@", [yCoordinates componentsJoinedByString:@", @"]);
    //NSLog(@"JSONObjectForInkPoints - times %@", [times componentsJoinedByString:@", @"]);
    
    return JSONObject;
}

#pragma mark - handwriting recognition results

- (void)clearHandwritingResults:(TrackingView *)trackingView placedholderText:(NSString *)text
{
    UIScrollView *resultsScrollView = [self resultsScrollView:trackingView];
    [resultsScrollView removeFromSuperview];
    
    if (text != nil) {
        [self update:trackingView withHandwritingResults:@[text]];
        [[self resultsSegmentedControl:trackingView] setEnabled:NO];
    }
}

- (void)update:(TrackingView *)trackingView withHandwritingResults:(NSArray *)results
{
    // create a new control showing the results
    UISegmentedControl *resultsSegmentedControl = [self resultsSegmentedControl:trackingView];
    [resultsSegmentedControl removeFromSuperview];

    resultsSegmentedControl = [[UISegmentedControl alloc] initWithItems:results];
    [resultsSegmentedControl setTag:TAG_SEGMENTEDCONTROL];
    [resultsSegmentedControl addTarget:self action:@selector(handwritingResultSelected:) forControlEvents:UIControlEventValueChanged];

    // resize the control
    UIEdgeInsets edgeInsets = [trackingView controlsEdgeInsets];
    CGRect resultsControlFrame = [resultsSegmentedControl frame];
    resultsControlFrame.size.height = MAX(resultsControlFrame.size.height, kTrackingViewMinControlHeight+edgeInsets.bottom*2);
    [resultsSegmentedControl setFrame:resultsControlFrame];


    // create a scroll view to contain the results
    CGSize resultsControlSize = [resultsSegmentedControl frame].size;
    UIScrollView *resultsScrollView = [self resultsScrollView:trackingView];
    if (resultsScrollView == nil) {
        CGRect trackingViewBounds = [trackingView bounds];
        
        // size the results view width to the tracking view and the height to the results control
        resultsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(trackingViewBounds) - resultsControlSize.height, trackingViewBounds.size.width, resultsControlSize.height)];
        [resultsScrollView setTag:TAG_SCROLLVIEW];
        [trackingView insertSubview:resultsScrollView atIndex:0];
    }
    
    [resultsScrollView setContentSize:resultsControlSize];
    [resultsScrollView addSubview:resultsSegmentedControl];
    
    [self sizeResultsScrollView:resultsScrollView toFitTrackingView:trackingView];
}

- (void)handwritingResultSelected:(UISegmentedControl *)control
{
    NSString *selectedResultText = [control titleForSegmentAtIndex:[control selectedSegmentIndex]];
    
    if ([control isDescendantOfView:_activeTrackingView]) {
        [self clear:_activeTrackingView];
        [[_activeTrackingView delegate] trackingView:_activeTrackingView didRecognizeText:selectedResultText];
    }
}

#pragma mark - helpers

- (void)sizeResultsScrollView:(UIScrollView *)resultsScrollView toFitTrackingView:(TrackingView *)trackingView
{
    CGRect trackingViewBounds = [trackingView bounds];

    // reset the scrollview width
    CGRect scrollviewFrame = [resultsScrollView frame];
    scrollviewFrame.origin.x = 0.0f;
    scrollviewFrame.size.width = trackingViewBounds.size.width;
    
    // bound the scrollview edges to avoid overlapping controls (assume scrollview and controls share a coordinate system)
    if ([trackingView controlsVisible]) {
        CGRect leftControlFrame = [[trackingView clearButton] frame];
        if (CGRectIntersectsRect(scrollviewFrame, leftControlFrame)) {
            scrollviewFrame.origin.x = CGRectGetMaxX(leftControlFrame);
            scrollviewFrame.size.width -= scrollviewFrame.origin.x;
        }
        
        CGRect rightControlFrame = [[trackingView backspaceKey] frame];
        if (CGRectIntersectsRect(scrollviewFrame, rightControlFrame)) {
            scrollviewFrame.size.width = CGRectGetMinX(rightControlFrame) - scrollviewFrame.origin.x;
        }
    }
    
    [resultsScrollView setFrame:scrollviewFrame];
    
    // position the results control in the middle of the scroll view
    UISegmentedControl *resultsSegmentedControl = [self resultsSegmentedControl:trackingView];
    CGRect resultsControlFrame = [resultsSegmentedControl frame];

    if (resultsControlFrame.size.width < scrollviewFrame.size.width) {
        resultsControlFrame.origin.x = scrollviewFrame.size.width/2 - resultsControlFrame.size.width/2;
        [resultsSegmentedControl setFrame:resultsControlFrame];
    }
}

- (UIScrollView *)resultsScrollView:(TrackingView *)trackingView
{
    UIScrollView *scrollView = (UIScrollView *)[trackingView viewWithTag:TAG_SCROLLVIEW];
    return scrollView;
}

- (UISegmentedControl *)resultsSegmentedControl:(TrackingView *)trackingView
{
    UISegmentedControl *segmentedControl = (UISegmentedControl *)[trackingView viewWithTag:TAG_SEGMENTEDCONTROL];
    return segmentedControl;
}

@end
