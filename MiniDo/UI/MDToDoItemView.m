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
#import "MDDataIO.h"
#import "MDAppControl.h"

#define TEXTFIELD_ALPHA_INCOMPLETE 1.0
#define TEXTFIELD_ALPHA_COMPLETE 0.5

@implementation MDToDoItemView
{
    UITextView *__textView; // show full text
    UILabel *__dateLabel;   // show creation/completion date
    UIButton *__deleteBtn;  // delete todo
    
}
@synthesize todo = _todo;
@synthesize isFocused = _isFocused;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        self.userInteractionEnabled = YES;
        _isFocused = NO;
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
    // Below view makes a tap-to-dismiss area on top of the keyboard.
    // It is simple and handy, but it blocks tap to move cursor on the textfield.
    // In order to keep the app simple, I stick with approach.
    UIView *keyboardDismissBtn = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    keyboardDismissBtn.backgroundColor = [UIColor clearColor];
    UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeKeyboard:)];
    [keyboardDismissBtn addGestureRecognizer:gr];
    keyboardDismissBtn.userInteractionEnabled = YES;
    self.textField.inputAccessoryView = keyboardDismissBtn;
    NSAttributedString *atrPlaceHolder = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Type in...", nil) attributes:@{NSFontAttributeName: self.textField.font, NSForegroundColorAttributeName: [UIColor colorWithWhite:1.0 alpha:0.5]}];
    self.textField.attributedPlaceholder = atrPlaceHolder;
    [self addSubview:self.textField];
    
}

#pragma mark - Actions -
-(void)pressedDoneBtn:(UIButton*)btn
{
    // change button appearance
    btn.selected = !btn.selected;
    BOOL isCompleted = btn.selected;
    
    // update todo data
    self.todo.isCompleted = @(isCompleted);
    if (isCompleted) {
        self.todo.completionDate = [NSDate date];
    } else {
        self.todo.creationDate = [NSDate date];
    }
    self.todo.isDirty = @(YES);
    
    [[MDDataIO sharedInstance] saveInBackgroundWithCompletionBlock:^(BOOL succeed) {
        
    }];
    
    // change textfield appearance
    if (isCompleted) {
        self.textField.alpha = TEXTFIELD_ALPHA_COMPLETE;
        __textView.alpha = TEXTFIELD_ALPHA_COMPLETE;
    } else {
        self.textField.alpha = TEXTFIELD_ALPHA_INCOMPLETE;
        __textView.alpha = TEXTFIELD_ALPHA_INCOMPLETE;
    }
    
    // start fly over animation!
    MDActiveListType sourceListType = isCompleted ? MDActiveListTypeToDo : MDActiveListTypeDone;
    MDActiveListType targetListType = isCompleted ? MDActiveListTypeDone : MDActiveListTypeToDo;
    [[MDAppControl sharedInstance] moveToDo:self.todo sourceListType:sourceListType targetListType:targetListType completionBlock:^{
        
    }];
    
}

-(void)pressedDeleteBtn:(UIButton*)btn
{
    // close keyboard if necessary
    [__textView resignFirstResponder];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete", nil) message:NSLocalizedString(@"Are you sure?", nil) preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    
    UIAlertAction *delete = [UIAlertAction actionWithTitle:NSLocalizedString(@"Delete", nil) style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"DELETE TODO: %@", self.todo.text);
        [self __commitDeleteAnimationWithCompletionBlock:^{
            // thrown out.
            // destroy data object and its parent cell
            [[MDAppControl sharedInstance] removeToDoItemWithToDo:self.todo];
            [[MDAppControl sharedInstance] forceToDismissFocusModeWithCompletionBlock:^{
                
            }];
        }];
    }];
    
    [alert addAction:cancel];
    [alert addAction:delete];
    
    UIViewController *baseVc = (UIViewController*)[MDAppControl sharedInstance].baseVc;
    
    [baseVc presentViewController:alert animated:YES completion:nil];
    
}

-(void)closeKeyboard:(UITapGestureRecognizer*)gr
{
    [self.textField resignFirstResponder];
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
    self.textField.text = _todo.text;
    __textView.text = _todo.text;
    if (_todo.isCompleted.boolValue == YES) {
        self.doneBtn.selected = YES;
        self.textField.alpha = TEXTFIELD_ALPHA_COMPLETE;
        __textView.alpha = TEXTFIELD_ALPHA_COMPLETE;
    } else {
        self.doneBtn.selected = NO;
        self.textField.alpha = TEXTFIELD_ALPHA_INCOMPLETE;
        __textView.alpha = TEXTFIELD_ALPHA_INCOMPLETE;
    }
}

-(void)setIsFocused:(BOOL)isFocused
{
    _isFocused = isFocused;
    
    if (isFocused) {
        // focus
        
        //TODO: refactoring!
        
        // full text
        if (__textView == nil) {
            __textView = [[UITextView alloc] initWithFrame:CGRectMake(self.textField.frame.origin.x-5, px2p(64), CGRectGetWidth(self.textField.bounds), px2p(400))];
            __textView.font = self.textField.font;
            __textView.textColor = self.textField.textColor;
            __textView.text = self.textField.text;
            __textView.delegate = self;
            __textView.returnKeyType = UIReturnKeyDone;
            __textView.alpha = 0.0;
            __textView.backgroundColor = [UIColor clearColor];
            [self addSubview:__textView];
        }
        
        // date label
        if (__dateLabel == nil) {
            __dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.textField.frame.origin.x+1, CGRectGetMaxY(__textView.frame), px2p(600), px2p(150))];
            [self addSubview:__dateLabel];
        }
        __dateLabel.alpha = 0.0;
        __dateLabel.backgroundColor = [UIColor clearColor];
        
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.doesRelativeDateFormatting = YES;
        formatter.locale = [NSLocale currentLocale];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterShortStyle;
        NSString *timeString = [formatter stringFromDate:self.todo.isCompleted.boolValue == NO ? self.todo.creationDate : self.todo.completionDate];
        NSString *finalString = [NSString stringWithFormat:@"%@%@", self.todo.isCompleted.boolValue == YES ? NSLocalizedString(@"DONE ", nil) : @"", timeString];
        if (timeString.length > 0) {
            NSMutableAttributedString *atr = [[NSMutableAttributedString alloc] initWithString:finalString attributes:@{NSFontAttributeName: [UIFont fontWithName:DEFAULT_FONT_LIGHT size:hdfs2fs(60)], NSForegroundColorAttributeName: DEFAULT_TEXT_COLOR}];
            NSRange rangeOfDoneString = [finalString rangeOfString:NSLocalizedString(@"DONE ", nil)];
            if (rangeOfDoneString.location != NSNotFound) {
                [atr addAttributes:@{NSForegroundColorAttributeName: DEFAULT_KEY_COLOR} range:rangeOfDoneString];
            }
            __dateLabel.attributedText = atr;
        }
      
        
        // delete button
        __deleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds)-px2p(60)-px2p(300), __dateLabel.frame.origin.y, px2p(300), px2p(150))];
        [__deleteBtn setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [__deleteBtn setTitle:NSLocalizedString(@"DELETE", nil) forState:UIControlStateNormal];
        __deleteBtn.titleLabel.font = [UIFont fontWithName:DEFAULT_FONT_LIGHT size:hdfs2fs(60)];
        [__deleteBtn addTarget:self action:@selector(pressedDeleteBtn:) forControlEvents:UIControlEventTouchUpInside];
        __deleteBtn.alpha = 0.0;
        [self addSubview:__deleteBtn];
        
        // disable done button
        // TODO: make it enabled.
        // --> this requires proper transition while focusing off, because target list view is different!
        self.doneBtn.userInteractionEnabled = NO;
        
        // expand height!
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, CGRectGetWidth(self.bounds), CGRectGetMaxY(__deleteBtn.frame));
        
        // animation
        [UIView animateWithDuration:0.3 animations:^{
            // swap text field and textview
            self.textField.alpha = 0.0;
            __textView.alpha = self.todo.isCompleted.boolValue == YES ? TEXTFIELD_ALPHA_COMPLETE : TEXTFIELD_ALPHA_INCOMPLETE;
            __dateLabel.alpha = 1.0;
            __deleteBtn.alpha = 1.0;
            
            
        }];
    } else {
        //de-focus
        
        // close keyboard if necessary
        [__textView resignFirstResponder];
        
        // make done button enabled
        self.doneBtn.userInteractionEnabled = YES;
        
        // reduce height!
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, CGRectGetWidth(self.bounds), TODO_CELL_HEIGHT);
        
        [UIView animateWithDuration:0.1 animations:^{
            // swap text field and textview
            self.textField.alpha = self.todo.isCompleted.boolValue == YES ? TEXTFIELD_ALPHA_COMPLETE : TEXTFIELD_ALPHA_INCOMPLETE;
            __textView.alpha = 0.0;
            __dateLabel.alpha = 0.0;
            __deleteBtn.alpha = 0.0;
            
        } completion:^(BOOL finished) {
            [__textView removeFromSuperview];
            __textView = nil;
            [__dateLabel removeFromSuperview];
            __dateLabel = nil;
            [__deleteBtn removeFromSuperview];
            __deleteBtn = nil;
            
        }];
        
    }
    
}

-(BOOL)isFocused
{
    return _isFocused;
}

-(void)__commitDeleteAnimationWithCompletionBlock:(nonnull void (^)())completionBlock
{
    CGAffineTransform t = CGAffineTransformConcat(
                                                  CGAffineTransformMakeTranslation(0, -CGRectGetHeight([UIScreen mainScreen].bounds)),
                                                  CGAffineTransformMakeRotation(deg2rad(10))
                                                  );
    
    // we block UI during this animation. we should be really careful when we block UI!
    // we MUST call -(void)unblockEntireUI! otherwise the app will be frozen!!!
    [[MDAppControl sharedInstance] blockEntireUI];
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        // push down
        self.transform = CGAffineTransformMakeTranslation(0, px2p(50));
    } completion:^(BOOL finished) {
        // throw out
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.transform = t;
        } completion:^(BOOL finished) {
            [[MDAppControl sharedInstance] unblockEntireUI];
            if (completionBlock) {
                completionBlock();
            }
        }];
    }];
}

#pragma mark - UITextField Delegate -
-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField.text.length == 0) {
        // we do not have text yet, because it is freshly created. we allow user input.
        return YES;
    } else {
        if (_isFocused == NO) {
            // once we set text, we do not allow text edit. Text can be edited in detail mode text view
            [[MDAppControl sharedInstance] focusOnToDo:self.todo completionBlock:^{
                
            }];
        }
        return NO;
    }
    
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    if (textField.text.length == 0) {
        // no todo body. we should destroy the cell
        [[MDAppControl sharedInstance] removeToDoItemWithToDo:self.todo];
        
    } else {
        // save this item as todo
        self.todo.text = textField.text;
        self.todo.creationDate = [NSDate date];
        self.todo.updatedAt = [NSDate date];
        self.todo.isDirty = @(YES);
        [[MDDataIO sharedInstance] saveInBackgroundWithCompletionBlock:^(BOOL succeed) {
            
        }];
    }
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    //ToDo: update textview in detail mode too!
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - UITextView Delegate -
-(void)textViewDidEndEditing:(UITextView *)textView
{
    // user edited todo text in focus mode. update todo data object and entire itemView content
    self.todo.text = textView.text;
    self.todo.isDirty = @(YES);
    
    self.textField.text = self.todo.text;
    
    [[MDDataIO sharedInstance] saveInBackgroundWithCompletionBlock:^(BOOL succeed) {
        
    }];
    
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        // todo item does not allow new line. this makes completion of todo text edit.
        [textView resignFirstResponder];
    }
    
    return YES;
}

@end
