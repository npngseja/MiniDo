//
//  MDToDoItemView.h
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MDToDoObject.h"
@interface MDToDoItemView : UIView <UITextFieldDelegate>


@property (nullable, nonatomic, strong) UIButton *doneBtn;

/**
 contains body text
 */
@property (nullable, nonatomic, strong) UITextField *textField;

/**
 set this property will change the view's content
 */
@property (nullable, nonatomic, strong) MDToDoObject *todo;

@end
