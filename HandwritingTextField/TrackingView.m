// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  TrackingView.m
//  HandwritingTextField
//
//  Created by Peter Lee on 1/17/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import "TrackingView.h"
#import "InkPoint.h"
#import "HandwritingRecognizer.h"

#define MIDPOINT(p1,p2)             CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5)

const CGFloat kTrackingViewMinControlWidth = 40.0f;
const CGFloat kTrackingViewMinControlHeight = 25.0f;

const CGFloat kMinDistance = 5;
const CGFloat kMinDistanceSquared = kMinDistance * kMinDistance;

@interface TrackingView ()
{
    CGPoint _currentPoint;
    CGPoint _previousPoint1;
    CGPoint _previousPoint2;
	
	CGMutablePathRef _strokePath;
    CGMutablePathRef _fillPath;
    BOOL _pathlessTouchEvent;
    
    NSMutableArray *_inkPoints;
}

@end

@implementation TrackingView

#pragma mark - lifecycle

- (void)initCommon
{
    _strokePath = CGPathCreateMutable();
    _fillPath = CGPathCreateMutable();
    
    _inkPoints = [NSMutableArray array];
    
    _controlsEdgeInsets = UIEdgeInsetsMake(5.0f, 0.0f, 5.0f, 0.0f);
    
    [self setExclusiveTouch:YES];
    [self setBackgroundColor:[UIColor clearColor]];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self initCommon];
    }
    
    return self;
}

- (void)dealloc
{
	CGPathRelease(_strokePath);
    CGPathRelease(_fillPath);
}

#pragma mark - controls

- (void)showControls
{
    CGRect trackingViewBounds = [self bounds];

    if (_doneButton == nil) {
        _doneButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_doneButton setImage:[UIImage imageNamed:@"done.png"] forState:UIControlStateNormal];
        [_doneButton addTarget:self action:@selector(doneTapped:) forControlEvents:UIControlEventTouchUpInside];

       [_doneButton sizeToFit];
        CGRect frame = [_doneButton frame];
        frame.size.width = MAX(frame.size.width, kTrackingViewMinControlWidth);
        frame.size.height = MAX(frame.size.height, kTrackingViewMinControlHeight);
        frame.origin.x = CGRectGetMaxX(trackingViewBounds) - frame.size.width - _controlsEdgeInsets.right;
        frame.origin.y = CGRectGetMinY(trackingViewBounds) + _controlsEdgeInsets.top;
        [_doneButton setFrame:frame];
        
        [self addSubview:_doneButton];
    }
    
    if (_showKeyboardButton == nil) {
        _showKeyboardButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_showKeyboardButton setImage:[UIImage imageNamed:@"keyboard.png"] forState:UIControlStateNormal];
        [_showKeyboardButton addTarget:self action:@selector(showKeyboardTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [_showKeyboardButton sizeToFit];
        CGRect frame = [_showKeyboardButton frame];
        frame.size.width = MAX(frame.size.width, kTrackingViewMinControlWidth);
        frame.size.height = MAX(frame.size.height, kTrackingViewMinControlHeight);
        frame.origin.x = CGRectGetMinX(trackingViewBounds) + _controlsEdgeInsets.left;
        frame.origin.y = CGRectGetMaxY(trackingViewBounds) - frame.size.height - _controlsEdgeInsets.bottom;
        [_showKeyboardButton setFrame:frame];
        
        [self addSubview:_showKeyboardButton];
    }

    if (_clearButton == nil) {
        _clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
        [_clearButton setImage:[UIImage imageNamed:@"trash.png"] forState:UIControlStateNormal];
        [_clearButton addTarget:self action:@selector(clearTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [_clearButton sizeToFit];
        CGRect frame = [_clearButton frame];
        frame.size.width = MAX(frame.size.width, kTrackingViewMinControlWidth);
        frame.size.height = MAX(frame.size.height, kTrackingViewMinControlHeight);
        frame.origin.x = CGRectGetMaxX([_showKeyboardButton frame]);
        frame.origin.y = CGRectGetMaxY(trackingViewBounds) - frame.size.height - _controlsEdgeInsets.bottom;
        [_clearButton setFrame:frame];
        
        [self addSubview:_clearButton];
    }

    if (_spaceKey == nil) {
        _spaceKey = [UIButton buttonWithType:UIButtonTypeSystem];
        [_spaceKey setImage:[UIImage imageNamed:@"space.png"] forState:UIControlStateNormal];
        [_spaceKey addTarget:self action:@selector(spaceTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [_spaceKey sizeToFit];
        CGRect frame = [_spaceKey frame];
        frame.size.width = MAX(frame.size.width, kTrackingViewMinControlWidth);
        frame.size.height = MAX(frame.size.height, kTrackingViewMinControlHeight);
        frame.origin.x = CGRectGetMaxX(trackingViewBounds) - frame.size.width - _controlsEdgeInsets.left;
        frame.origin.y = CGRectGetMaxY(trackingViewBounds) - frame.size.height - _controlsEdgeInsets.bottom;
        [_spaceKey setFrame:frame];
        
        [self addSubview:_spaceKey];
    }
    
    if (_backspaceKey == nil) {
        _backspaceKey = [UIButton buttonWithType:UIButtonTypeSystem];
        [_backspaceKey setImage:[UIImage imageNamed:@"backspace.png"] forState:UIControlStateNormal];
        [_backspaceKey addTarget:self action:@selector(backspaceTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        [_backspaceKey sizeToFit];
        CGRect frame = [_backspaceKey frame];
        frame.size.width = MAX(frame.size.width, kTrackingViewMinControlWidth);
        frame.size.height = MAX(frame.size.height, kTrackingViewMinControlHeight);
        frame.origin.x = CGRectGetMinX([_spaceKey frame]) - frame.size.width;
        frame.origin.y = CGRectGetMaxY(trackingViewBounds) - frame.size.height - _controlsEdgeInsets.bottom;
        [_backspaceKey setFrame:frame];
        
        [self addSubview:_backspaceKey];
    }

    
    [_doneButton setHidden:NO];
    [_showKeyboardButton setHidden:NO];
    [_clearButton setHidden:NO];
    [_backspaceKey setHidden:NO];
    [_spaceKey setHidden:NO];
}

- (void)hideControls
{
    [_doneButton setHidden:YES];
    [_showKeyboardButton setHidden:YES];
    [_clearButton setHidden:YES];
    [_backspaceKey setHidden:YES];
    [_spaceKey setHidden:YES];
}

- (void)setControlsVisible:(BOOL)hidden
{
    _controlsVisible = hidden;
    
    if (_controlsVisible) {
        [self showControls];
    } else {
        [self hideControls];
    }
}

#pragma mark - control events

- (void)doneTapped:(UIButton *)button
{
    [_delegate trackingView:self didReceiveEvent:TrackingViewEventDone];
}

- (void)showKeyboardTapped:(UIButton *)button
{
    [_delegate trackingView:self didReceiveEvent:TrackingViewEventShowKeyboard];
}

- (void)clearTapped:(UIButton *)button
{
    [_delegate trackingView:self didReceiveEvent:TrackingViewEventClear];
}

- (void)spaceTapped:(UIButton *)button
{
    [_delegate trackingView:self didReceiveEvent:TrackingViewEventSpace];
}

- (void)backspaceTapped:(UIButton *)button
{
    [_delegate trackingView:self didReceiveEvent:TrackingViewEventBackspace];
}


#pragma mark - tracking management

- (NSArray *)inkPoints
{
    return [NSArray arrayWithArray:_inkPoints];
}

- (void)clearInk
{
    [_inkPoints removeAllObjects];
    
    CGPathRelease(_strokePath);
    CGPathRelease(_fillPath);
    _strokePath = CGPathCreateMutable();
    _fillPath = CGPathCreateMutable();
    
    [self setNeedsDisplay];
}


#pragma mark - touch tracking

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[HandwritingRecognizer sharedRecognizer] cancelFetchHandwritingRecognitionResults];
    
    UITouch *touch = [touches anyObject];
    
    _previousPoint1 = [touch previousLocationInView:self];
    _previousPoint2 = [touch previousLocationInView:self];
    _currentPoint = [touch locationInView:self];
    _pathlessTouchEvent = YES;
    
    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
	
    // save touch point
	CGPoint point = [touch locationInView:self];
	[_inkPoints addObject:[[InkPoint alloc] initWithPoint:point]];
    
    // pathless point until we move a minimum distance
    CGFloat dx = point.x - _currentPoint.x;
    CGFloat dy = point.y - _currentPoint.y;
    if ((dx * dx + dy * dy) < kMinDistanceSquared) {
        return;
    }
    _pathlessTouchEvent = NO;
    
    _previousPoint2 = _previousPoint1;
    _previousPoint1 = [touch previousLocationInView:self];
    _currentPoint = [touch locationInView:self];
    
    CGPoint mid1 = MIDPOINT(_previousPoint1, _previousPoint2);
    CGPoint mid2 = MIDPOINT(_currentPoint, _previousPoint1);
	CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, _previousPoint1.x, _previousPoint1.y, mid2.x, mid2.y);
    CGRect bounds = CGPathGetBoundingBox(subpath);
	
	CGPathAddPath(_strokePath, NULL, subpath);
	CGPathRelease(subpath);
    
    CGRect drawBox = bounds;
    CGFloat lineWidth = [[HandwritingRecognizer sharedRecognizer] lineWidth];
    drawBox.origin.x -= lineWidth * 2.0;
    drawBox.origin.y -= lineWidth * 2.0;
    drawBox.size.width += lineWidth * 4.0;
    drawBox.size.height += lineWidth * 4.0;
    
    [self setNeedsDisplayInRect:drawBox];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_pathlessTouchEvent) {
        CGFloat lineWidth = [[HandwritingRecognizer sharedRecognizer] lineWidth];
        CGRect pointRect = CGRectMake(_currentPoint.x-lineWidth/2, _currentPoint.y-lineWidth/2, lineWidth, lineWidth);
        CGPathAddEllipseInRect(_fillPath, NULL, pointRect);
        
        [self setNeedsDisplayInRect:pointRect];
    }
    
    [[HandwritingRecognizer sharedRecognizer] fetchHandwritingRecognitionResultsAfterDelay];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[HandwritingRecognizer sharedRecognizer] fetchHandwritingRecognitionResultsAfterDelay];
}

#pragma mark - path drawing

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGFloat lineWidth = [[HandwritingRecognizer sharedRecognizer] lineWidth];
    UIColor *lineColor = [[HandwritingRecognizer sharedRecognizer] lineColor];
    
    // clear drawing rect
    CGContextSetFillColorWithColor(context, [[self backgroundColor] CGColor]);
    CGContextFillRect(context, rect);
    
    // draw paths
	CGContextAddPath(context, _strokePath);
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetStrokeColorWithColor(context, [lineColor CGColor]);
    
    CGContextStrokePath(context);
    
    // draw pathless points
    CGContextAddPath(context, _fillPath);
    CGContextSetFillColorWithColor(context, [lineColor CGColor]);
    CGContextFillPath(context);
}

@end
