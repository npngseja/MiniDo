//
//  MDToDoItemView.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDToDoObject.h"
@interface MDToDoItemView : UIView <UITextFieldDelegate, UITextViewDelegate>


@property (nullable, nonatomic, strong) UIButton *doneBtn;

/**
 contains body text
 */
@property (nullable, nonatomic, strong) UITextField *textField;


/**
 set this property will change the view's content
 */
@property (nullable, nonatomic, strong) MDToDoObject *todo;

/**
 whether this item view is focused (out of the table view) ot not (inside its parent cell)
 this will expand/collapse details
 */
@property BOOL isFocused;

/**
 YES if textView or textField is editing
 */
@property (readonly) BOOL isEditing;

/**
 dismiss keyboard
 */
-(void)deactivate;


/**
 will prompt text should have a text. this might happen when user removed all text and want to dismiss focused mode. we should prevent it.
 */
-(void)promptDeletionOfCurrentToDo;


@end
