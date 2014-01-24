//
//  ViewController.m
//  HandwritingTextFieldDemo
//
//  Created by Peter Lee on 1/16/14.
//  Copyright (c) 2014 Peter Lee. All rights reserved.
//

#import "ViewController.h"
#import "UITextField+Handwriting.h"
#import "TrackingView.h"

@interface ViewController ()

@property (nonatomic, weak) IBOutlet UITextField *textFieldDefault;
@property (nonatomic, weak) IBOutlet UITextField *textFieldCustomView;
@property (nonatomic, weak) IBOutlet UIView *customHandwritingView;


@end

@implementation ViewController

#pragma mark - lifecycle 

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [_textFieldDefault setHandwritingEnabled:YES];
    [_textFieldDefault setHandwritingView:[self view]];
    [_textFieldDefault setDelegate:self];
    
    [_textFieldCustomView setHandwritingEnabled:YES];
    [_textFieldCustomView setHandwritingView:_customHandwritingView];
    [_textFieldCustomView setDelegate:self];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [tapRecognizer setDelegate:self];
    [[self view] addGestureRecognizer:tapRecognizer];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    BOOL shouldBeginEditing = YES;
    
    if ([textField handwritingEnabled]) {
        [textField beginHandwriting];
    }
    
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
        shouldReceiveTouch = NO;
    }
    
    return shouldReceiveTouch;
}

@end
