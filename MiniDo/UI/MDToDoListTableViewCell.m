//
//  MDToDoListTableViewCell.m
//  MiniDo
//
//  Created by npngseja on 24/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDToDoListTableViewCell.h"

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
    self.contentView.frame = self.bounds;
    if (self.todoItemView == nil) {
        // we create item view here after we know cell's actual size.
        // this method is called frequently, so the 'nil' check is super important. 
        self.todoItemView = [[MDToDoItemView alloc] initWithFrame:self.contentView.bounds];
        [self.contentView addSubview:self.todoItemView];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark - ToDo Item View Related -
-(void)updateToDoObject:(MDToDoObject *)todo
{
    
}

@end
