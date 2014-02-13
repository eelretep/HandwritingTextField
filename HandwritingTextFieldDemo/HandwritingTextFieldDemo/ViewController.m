// This file is part of the HandwritingTextField package.
//
// For the full copyright and license information, please view the LICENSE file that was distributed with this source code.
// https://github.com/eelretep/HandwritingTextField
//
//  ViewController.m
//  HandwritingTextFieldDemo
//
//  Created by Peter Lee on 1/16/14.
//  Copyright (c) 2014 Peter Lee <eelretep@gmail.com>. All rights reserved.
//

#import "ViewController.h"
#import "UITextField+Handwriting.h"
#import "TrackingView.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textFieldFullscreenView;
@property (nonatomic, weak) IBOutlet UITextField *textFieldCustomView;
@property (nonatomic, weak) IBOutlet UIView *customHandwritingView;
@property (nonatomic, weak) IBOutlet UISwitch *switchControlsVisible;

@end

@implementation ViewController

#pragma mark - lifecycle 

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_textFieldFullscreenView setHandwritingView:[self view]];
    [_textFieldFullscreenView setDelegate:self];
    
    [_textFieldCustomView setHandwritingView:_customHandwritingView];
    [_textFieldCustomView setDelegate:self];
    
    // tap to end editing
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapRecognizer setDelegate:self];
    [[self view] addGestureRecognizer:tapRecognizer];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL shouldBeginEditing = YES;
    
    [textField setHandwritingControlsVisible:[_switchControlsVisible isOn]];
    [textField beginHandwriting];
    
    return shouldBeginEditing;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [textField endHandwriting];
}

#pragma mark - gesture recognizer

- (void)handleTap:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [[self view] endEditing:YES];
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldReceiveTouch = YES;

    if ([[touch view] isKindOfClass:[TrackingView class]]) {
        // don't intercept handwriting tracking touches 
        shouldReceiveTouch = NO;
    }
    
    return shouldReceiveTouch;
}

#pragma mark - UI

- (IBAction)handleSwitchControlsVisible:(UISwitch *)sender
{
    if ([_textFieldCustomView isFirstResponder]) {
        [_textFieldCustomView  setHandwritingControlsVisible:[sender isOn]];
    }
}
@end
