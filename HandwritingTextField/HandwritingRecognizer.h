// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  HandwritingRecognizer.h
//  HandwritingTextField
//
//  Created by Peter Lee on 1/16/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TrackingView;

@interface HandwritingRecognizer : NSObject

+ (instancetype)sharedRecognizer;

- (TrackingView *)overlayTrackingViewInView:(UIView *)view;
- (BOOL)startTrackingHandwriting:(TrackingView *)trackingView;
- (void)stopTrackingHandwriting:(TrackingView *)trackingView;
- (void)clear:(TrackingView *)trackingView; // clears handwriting tracking and results
- (void)layoutControls:(TrackingView *)trackingView;

- (void)fetchHandwritingRecognitionResultsAfterDelay; // cancels current fetch request, if in progress, and re-fetches (useful for gesture events)
- (void)fetchHandwritingRecognitionResults; // does not cancel current in progress fetch
- (void)cancelFetchHandwritingRecognitionResults;

@property (nonatomic) UIColor *lineColor; // color of traced handwriting
@property (readwrite) CGFloat lineWidth; // width of traced handwriting

@end
