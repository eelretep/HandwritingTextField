//
//  HandwritingRecognizer.h
//  HandwritingTextField
//
//  Created by Peter Lee on 1/16/14.
//  Copyright (c) 2014 Peter Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TrackingView;

@interface HandwritingRecognizer : NSObject

+ (instancetype)sharedRecognizer;

- (TrackingView *)overlayTrackingViewInView:(UIView *)view;
- (BOOL)startTrackingHandwriting:(TrackingView *)trackingView;
- (void)stopTrackingHandwriting:(TrackingView *)trackingView;
- (void)clearHandwriting:(TrackingView *)trackingView;

- (void)fetchHandwritingRecognitionResultsAfterDelay;
- (void)cancelFetchHandwritingRecognitionResults;

@property (nonatomic) UIColor *lineColor;
@property (readwrite) CGFloat lineWidth;

@end
