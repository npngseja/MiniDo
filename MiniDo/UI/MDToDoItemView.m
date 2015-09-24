//
//  MDToDoItemView.m
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDToDoItemView.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"

@implementation MDToDoItemView
@synthesize todo = _todo;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.userInteractionEnabled = YES;
        [self __configureView];
    }
    
    return self;
}

-(void)__configureView
{
    // init done button
    CAShapeLayer *doneBtnBg = [CAShapeLayer layer];
    doneBtnBg.frame = CGRectMake(px2p(80), px2p(100), px2p(100), px2p(100));
    doneBtnBg.path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, CGRectGetWidth(doneBtnBg.frame), CGRectGetHeight(doneBtnBg.frame)) cornerRadius:CGRectGetHeight(doneBtnBg.frame)/2].CGPath;
    doneBtnBg.fillColor = NULL;
    doneBtnBg.lineWidth = 1;
    doneBtnBg.strokeColor = DEFAULT_COLOR_WHITE.CGColor;
    doneBtnBg.opacity = 0.6;
    [self.layer addSublayer:doneBtnBg];
    
    self.doneBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, px2p(200), px2p(200))];
    self.doneBtn.center = doneBtnBg.position;
    UIImage *btnImg = [[UIImage imageNamed:@"Check"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.doneBtn setImage:nil forState:UIControlStateNormal];
    [self.doneBtn setImage:nil forState:UIControlStateHighlighted];
    [self.doneBtn setImage:nil forState:UIControlStateNormal | UIControlStateHighlighted];
    [self.doneBtn setImage:btnImg forState:UIControlStateSelected];
    [self.doneBtn setTintColor:DEFAULT_KEY_COLOR];
    [self.doneBtn addTarget:self action:@selector(pressedDoneBtn:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:self.doneBtn];
    
    // init textfield
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(px2p(250), 0, CGRectGetWidth(self.bounds)-px2p(250)-px2p(192), CGRectGetHeight(self.bounds))]; // 192px for reorder control
    self.textField.font = [UIFont fontWithName:DEFAULT_FONT_REGULAR size:hdfs2fs(90)];
    self.textField.textColor = DEFAULT_TEXT_COLOR;
    self.textField.delegate = self;
    self.textField.returnKeyType = UIReturnKeyDone;
    //self.textField.text = @"This is Dummy!";
    NSAttributedString *atrPlaceHolder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Type in...", nil) attributes:@{NSFontAttributeName: self.textField.font, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.5]}];
    self.textField.attributedPlaceholder = atrPlaceHolder;
    [self addSubview:self.textField];
    
}

#pragma mark - Button Actions -
-(void)pressedDoneBtn:(UIButton*)btn
{
    // change button appearance
    btn.selected = !btn.selected;
    BOOL isCompleted = btn.selected;
    
    // update todo data
    self.todo.isCompleted = @(isCompleted);
    
    // change textfield appearance
    if (isCompleted) {
        self.textField.alpha = 0.5;
    } else {
        self.textField.alpha = 1.0;
    }
}

#pragma mark - Content Management -
-(MDToDoObject*)todo
{
    return _todo;
}

-(void)setTodo:(MDToDoObject *)todo
{
    _todo = todo;
    [self __updateContentWithCurrentToDoObject];
}

-(void)__updateContentWithCurrentToDoObject
{
    
}

#pragma mark - UITextField Delegate -
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField.text.length == 0) {
        // we do not have text yet, because it is freshly created. we allow user input.
        return YES;
    } else {
        // once we set text, we do not allow text edit. Text can be edited in detail mode text view
        return NO;
    }
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //ToDo: update textview in detail mode too!
    [textField resignFirstResponder];
    return YES;
}

@end
