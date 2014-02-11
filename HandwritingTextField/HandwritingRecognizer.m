//
//  HandwritingRecognizer.m
//  HandwritingTextField
//
//  Created by Peter Lee on 1/16/14.
//  Copyright (c) 2014 Peter Lee. All rights reserved.
//

#import "HandwritingRecognizer.h"
#import "TrackingView.h"
#import "InkPoint.h"

#define DEFAULT_LINECOLOR               [UIColor blackColor]
#define DEFAULT_LINEWIDTH               5.0f

#define TAG_SEGMENTEDCONTROL            1000
#define TAG_SCROLLVIEW                  1001

const NSTimeInterval kDelayBeforeFetch  = 1.5;
NSString * const kNoResultsText         = @"No Handwriting Results";

@interface HandwritingRecognizer() {
    TrackingView *_activeTrackingView;
    
    NSURLSessionUploadTask *_handwritingRecognitionTask;
}

@end



@implementation HandwritingRecognizer

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
        [self setLineColor:DEFAULT_LINECOLOR];
        [self setLineWidth:DEFAULT_LINEWIDTH];
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
        
        if (CGRectEqualToRect([_activeTrackingView bounds], [[_activeTrackingView window] bounds])) {
            //tracking in fullscreen
            if ([[UIApplication sharedApplication] isStatusBarHidden] == NO) {
                UIEdgeInsets edgeInsets = [_activeTrackingView controlsEdgeInsets];
                edgeInsets.top = 20.0f;
                [_activeTrackingView setControlsEdgeInsets:edgeInsets];
            }
            
            [_activeTrackingView setControlsVisible:YES];
        }
        
        [self clearHandwriting:_activeTrackingView];
        
        success = YES;
    }
    
    return success;
}

- (void)stopTrackingHandwriting:(TrackingView *)trackingView
{
    [trackingView removeFromSuperview];
    //[trackingView stopUpdating];
    
    if (_activeTrackingView == trackingView) {
        _activeTrackingView = nil;

        [self clearHandwriting:_activeTrackingView];
    }
}

- (void)clearHandwriting:(TrackingView *)trackingView {
    
    [trackingView clearInk];
    [self clearHandwritingResults:trackingView placedholderText:kNoResultsText];
    
    if (_activeTrackingView == trackingView) {
        [self cancelFetchHandwritingRecognitionResults];
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
            
            NSLog(@"requestOCRForInkPoints (%@)  %@ \n\n--------------->\n\n %@", urlRequest, requestJSON, responseJSON);
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
    
    return JSONObject;
}

#pragma mark - display handwriting results

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
    CGRect trackingViewBounds = [trackingView bounds];
    CGSize resultsControlSize = [resultsSegmentedControl frame].size;
    
    UIScrollView *resultsScrollView = [self resultsScrollView:trackingView];
    if (resultsScrollView == nil) {
        // size the results view width to the tracking view and the height to the results control
        resultsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0f, CGRectGetMaxY(trackingViewBounds) - resultsControlSize.height, trackingViewBounds.size.width, resultsControlSize.height)];
        [resultsScrollView setTag:TAG_SCROLLVIEW];
        [trackingView insertSubview:resultsScrollView atIndex:0];
    }
    
    // position the results control in the middle of the tracking/scroll view
    if (resultsControlSize.width < trackingViewBounds.size.width) {
        CGRect frame = [resultsSegmentedControl frame];
        frame.origin.x = CGRectGetMidX(trackingViewBounds) - frame.size.width/2;
        [resultsSegmentedControl setFrame:frame];
    }
    [resultsScrollView setContentSize:resultsControlSize];
    [resultsScrollView addSubview:resultsSegmentedControl];

    
    // reset the scrollview width
    CGRect scrollviewFrame = [resultsScrollView frame];
    scrollviewFrame.origin.x = 0.0f;
    scrollviewFrame.size.width = trackingViewBounds.size.width;
    [resultsScrollView setFrame:scrollviewFrame];
    
    // bound the scrollview edges to avoid overlapping controls (assume scrollview and controls share a coordinate system)
    if ([trackingView controlsVisible]) {
        CGRect contentFrame = [trackingView convertRect:[resultsSegmentedControl frame] fromView:resultsScrollView];
        CGRect leftControlFrame = [[trackingView showKeyboardButton] frame];
        if (CGRectIntersectsRect(contentFrame, leftControlFrame)) {
            scrollviewFrame.origin.x = CGRectGetMaxX(leftControlFrame);
            scrollviewFrame.size.width -= scrollviewFrame.origin.x;
            [resultsScrollView setFrame:scrollviewFrame];
        }
        
        contentFrame = [trackingView convertRect:[resultsSegmentedControl frame] fromView:resultsScrollView];
        CGRect rightControlFrame = [[trackingView backspaceKey] frame];
        if (CGRectIntersectsRect(contentFrame, rightControlFrame)) {
            scrollviewFrame.size.width = CGRectGetMinX(rightControlFrame) - scrollviewFrame.origin.x;
            [resultsScrollView setFrame:scrollviewFrame];
        }
    }

    
    

    
}

- (void)handwritingResultSelected:(UISegmentedControl *)control
{
    NSString *selectedResultText = [control titleForSegmentAtIndex:[control selectedSegmentIndex]];
    
    [control setEnabled:NO];
    
    UIView *view = [[control superview] superview];
    if ([view isKindOfClass:[TrackingView class]]) {
        TrackingView *trackingView = (TrackingView *)view;
        [self clearHandwriting:trackingView];
        [[trackingView delegate] trackingView:trackingView didRecognizeText:selectedResultText];
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
