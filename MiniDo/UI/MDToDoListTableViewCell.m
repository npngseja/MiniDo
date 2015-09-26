//
//  MDToDoListTableViewCell.m
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDToDoListTableViewCell.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"

@implementation MDToDoListTableViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark - ToDo Item View Related -
-(void)updateToDoObject:(MDToDoObject *)todo
{
    if (self.todoItemView == nil) {
        self.todoItemView = [[MDToDoItemView alloc] initWithFrame:CGRectMake(0, 0, TODO_CELL_WIDTH, TODO_CELL_HEIGHT)];
        [self.contentView addSubview:self.todoItemView];
    }
    
    [self.todoItemView setTodo:todo];
}

-(void)startToDoTextEdit
{
    if (self.todoItemView.todo.text.length == 0) {
        [self.todoItemView.textField becomeFirstResponder];
    }
}
@end
