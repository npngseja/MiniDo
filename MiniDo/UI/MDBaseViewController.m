//
//  MDBaseViewController.m
//  MiniDo
//
//  Created by npngseja on 23/09/15.
//  Copyright © 2015 Taehun Kim. All rights reserved.
//

#import "MDBaseViewController.h"
#import "MDMiniDoConstants.h"
#import "MDMiniDoUtils.h"
#import "MDAppControl.h"
#import "MDToDoItemView.h"

#define CONTENT_VIEW_FRAME_IPAD CGRectMake(100, 68, 815, 632)
#define CREATION_BUTTON_BG_COLOR_PLUS [UIColor colorWithWhite:1.0 alpha:0.8]
#define CREATION_BUTTON_BG_COLOR_ARROW [UIColor clearColor]


@interface MDBaseViewController ()
{
    BOOL __isFirstLoad;
    UIView *__contentView;  // contains scroller, header and add button
    UIView *__layerInvisibleDismissFocusedToDo; // tap on it will dismiss focused todo.
}
@end

@implementation MDBaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // this is the first load of the viewcontroller
    __isFirstLoad = YES;
    
    // set application background
    self.view.backgroundColor = DEFAULT_BG_COLOR;
    
    // set background image
    CALayer *bg_layer = [CALayer layer];
    bg_layer.frame = self.view.bounds;
    bg_layer.contentsGravity = kCAGravityResizeAspectFill;
    [self.view.layer addSublayer:bg_layer];
    
    // dimming background image for a better readable app
    CALayer *overlay = [CALayer layer];
    overlay.frame = bg_layer.bounds;
    overlay.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2].CGColor;
    [bg_layer addSublayer:overlay];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *bgImgPath = [[NSBundle mainBundle] pathForResource:@"Background" ofType:@"jpg"];
        UIImage *bgImg = [UIImage imageWithContentsOfFile:bgImgPath];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            bg_layer.contents = (id)bgImg.CGImage;
        });
    });
    
    __contentView = [[UIView alloc] initWithFrame:self.view.bounds];
    __contentView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    __contentView.userInteractionEnabled = YES;
    [self.view addSubview:__contentView];
    
    CGFloat scrollerContentSizeScale = 2.0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // we make contentView different for iPad app, with 100p side margins
        __contentView.frame = CONTENT_VIEW_FRAME_IPAD;
        scrollerContentSizeScale = 1.0;
    }
    
    // base scroller
    self.scroller = [[UIScrollView alloc] initWithFrame:CGRectMake(0, px2p(370), CGRectGetWidth(__contentView.bounds), CGRectGetHeight(__contentView.bounds) - px2p(370))];
    self.scroller.showsHorizontalScrollIndicator = NO;
    self.scroller.showsVerticalScrollIndicator = NO;
    self.scroller.pagingEnabled = YES;
    self.scroller.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    self.scroller.delegate = self;
    self.scroller.contentSize = CGSizeMake(CGRectGetWidth(self.scroller.bounds)*scrollerContentSizeScale, CGRectGetHeight(self.scroller.bounds));
    [__contentView addSubview:self.scroller];
    
    CGFloat listViewWidth = CGRectGetWidth(self.scroller.bounds);
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // we show two list views side by side
        listViewWidth = CGRectGetWidth(self.scroller.bounds)/2;
    }
    
    // todo list view controller
    self.todoListViewController = [[MDToDoListViewController alloc] init];
    self.todoListViewController.view.frame = CGRectMake(0, 0, listViewWidth, CGRectGetHeight(self.scroller.bounds));
    self.todoListViewController.listType = MDActiveListTypeToDo;
    [self.scroller addSubview:self.todoListViewController.view];
    
    // done list view controller
    self.doneListViewController = [[MDToDoListViewController alloc] init];
    self.doneListViewController.view.frame = CGRectMake(listViewWidth, 0, listViewWidth, CGRectGetHeight(self.scroller.bounds));
    self.doneListViewController.listType = MDActiveListTypeDone;
    [self.scroller addSubview:self.doneListViewController.view];
    
    // add button
    self.addBtn = [[MDBaseAddBtn alloc] initWithFrame:CGRectMake(0, 0, px2p(256), px2p(256))];
    self.addBtn.translatesAutoresizingMaskIntoConstraints = NO;
    [self.addBtn addTarget:self action:@selector(pressedAddBtn:) forControlEvents:UIControlEventTouchUpInside];
    self.addBtn.tintColor = DEFAULT_KEY_COLOR;
    self.addBtn.layer.cornerRadius = CGRectGetHeight(self.addBtn.bounds)/2;
    self.addBtn.backgroundColor = CREATION_BUTTON_BG_COLOR_PLUS;
    self.addBtn.clipsToBounds = YES;
    [self.view addSubview:self.addBtn];
    [self.view addConstraints:@[[NSLayoutConstraint constraintWithItem:self.addBtn
                                                             attribute:NSLayoutAttributeWidth
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:px2p(256)],
                                [NSLayoutConstraint constraintWithItem:self.addBtn
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:nil
                                                             attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:px2p(256)],
                                [NSLayoutConstraint constraintWithItem:self.addBtn
                                                          attribute:NSLayoutAttributeBottom
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeBottom
                                                         multiplier:1.0 constant:-px2p(56)],
                                [NSLayoutConstraint constraintWithItem:self.addBtn
                                                             attribute:NSLayoutAttributeCenterX
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self.view
                                                             attribute:NSLayoutAttributeCenterX
                                                            multiplier:1.0 constant:0],
                                ]];
    // header
    self.headerView = [[MDBaseHeaderView alloc] initWithFrame:CGRectMake(0, 20+px2p(34), CGRectGetWidth(__contentView.bounds), px2p(250))];
    [__contentView addSubview:self.headerView];
    
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (__isFirstLoad == YES) {
        
        // do app launch sequence
        [[MDAppControl sharedInstance] doAppLaunchSequenceWithCompletionBlock:^{
            
        }];
        
        
        // view is loaded
        __isFirstLoad = NO;
    }
    
}

#pragma mark - Action -
-(void)pressedAddBtn:(MDPopButton*)btn
{
    if ([MDAppControl sharedInstance].isFocusMode == YES) {
        // focus mode. dismiss focus mode
        [[MDAppControl sharedInstance] dismissCurrentFocusToDoWithCompletionBlock:^{
            
        }];
    } else {
        // normal mode. add new item
        [[MDAppControl sharedInstance] setActiveListType:MDActiveListTypeToDo animated:YES completionBlock:^{
            [[MDAppControl sharedInstance] insertNewToDoItemOnToDoList];
        }];
    }
}

-(void)tappedOnDismissFocusedToDoLayer:(UITapGestureRecognizer*)gr
{
    [[MDAppControl sharedInstance] dismissCurrentFocusToDoWithCompletionBlock:^{
        
    }];
}

#pragma mark - UIScrollView Delegate (BaseScroller) -
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{

    // we sync scroller and headerView's view changes here
    
    // progress is 0 ... 1.
    // 0 : ToDo list is active
    // 1 : Done list is active
    CGFloat transitionProgress = scrollView.contentOffset.x / CGRectGetWidth(scrollView.bounds);
    [self.headerView layoutWithTransitionProgress:transitionProgress];
    
}

#pragma mark - Focus on/off
-(void)__makeContentViewFarAway
{
    __contentView.alpha = 0.1;
    // for the simplicity, we user view-based animation and simulate depth of the view by scale control.
    // better would be controling CATransform3D.z
    __contentView.transform = CGAffineTransformMakeScale(0.9, 0.9);
}

-(void)__makeContentViewNormal
{
    __contentView.alpha = 1.0;
    // to simplicity, we user view-based animation and simulate depth of the view by scale control.
    // better would be controling CATransform3D.z
    __contentView.transform = CGAffineTransformMakeScale(1.0, 1.0);

}

-(void)focusOnToDo:(MDToDoObject *)todo completionBlock:(void (^)(BOOL succceed))completionBlock
{
    MDToDoListViewController *targetVc = todo.isCompleted.boolValue == YES ? self.doneListViewController : self.todoListViewController;
    
    MDToDoItemView *itemView = [targetVc todoItemViewForToDoObject:todo];
    if (itemView == nil) {
        NSLog(@"[MDBaseViewController] item view for the given todo is not found!");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
    // mark this item view as fouces
    itemView.isFocused = YES;
    
    
    // show invisible layer to dismiss focusing todo
    if (__layerInvisibleDismissFocusedToDo == nil) {
        __layerInvisibleDismissFocusedToDo = [[UIView alloc] initWithFrame:self.view.bounds];
        __layerInvisibleDismissFocusedToDo.userInteractionEnabled = YES;
        __layerInvisibleDismissFocusedToDo.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5];
        __layerInvisibleDismissFocusedToDo.alpha = 0.0;
        UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnDismissFocusedToDoLayer:)];
        [__layerInvisibleDismissFocusedToDo addGestureRecognizer:gr];
    }
    [self.view insertSubview:__layerInvisibleDismissFocusedToDo belowSubview:self.addBtn];
    
    // take the view out of the cell and put on top of other view
    CGPoint centerOnBaseVc = [itemView convertPoint:CGPointMake(CGRectGetWidth(itemView.bounds)/2, CGRectGetHeight(itemView.bounds)/2) toView:self.view];
    itemView.center = centerOnBaseVc;
    [self.view addSubview:itemView];
    
    //
    // animation!
    //
    CGFloat itemViewDestCenterY = UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ? px2p(772) : 260; // these values are found with my eyes...
    
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options: UIViewAnimationOptionCurveEaseInOut animations:^{
        
        itemView.center = CGPointMake(CGRectGetWidth(self.view.bounds)/2, itemViewDestCenterY);
        [self __makeContentViewFarAway];
        __layerInvisibleDismissFocusedToDo.alpha = 1.0;
        
        // change add button's bg color
        self.addBtn.backgroundColor = CREATION_BUTTON_BG_COLOR_ARROW;
    } completion:^(BOOL finished) {
        if (completionBlock) {
            completionBlock(YES);
        }
    }];
    
    // make add button arrow
    [self.addBtn makeArrow];
    
}

-(void)dismissToDoFocus:(nonnull MDToDoObject*)todo
        completionBlock:(nullable void (^)(BOOL succeed))completionBlock
{
    MDToDoListViewController *targetVc = todo.isCompleted.boolValue == YES ? self.doneListViewController : self.todoListViewController;
    
    MDToDoItemView *itemView = [targetVc todoItemViewForToDoObject:todo];
    if (itemView == nil) {
        NSLog(@"[MDBaseViewController] item view for the given todo is not found!");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
    // check if todo has no text anymore
    if (todo.text.length == 0) {
        [itemView promptDeletionOfCurrentToDo];
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
   
    // calc destination of itemview concerning its parent cell
    NSValue *destinationOnListView = [targetVc putBackDestinationCenterOfTodoItemViewOnTableView:itemView];
    if (destinationOnListView == nil) {
        NSLog(@"[MDBaseViewController] item view is probably not found in target list view!");
        if (completionBlock) {
            completionBlock(NO);
        }
        return;
    }
    
    // we do not use here -(CGPoint)convertPoint:toView: method, because __contentView is scaled, so that the conversion has influence of that scaling. We need to know the cell's position when the list is NOT scaled. To achieve that we calculate destination center on screen manually.
    CGFloat targetVcOriginX = 0;
    CGFloat contentViewOriginX = 0;
    CGFloat contentViewOriginY = 0;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        contentViewOriginX = CONTENT_VIEW_FRAME_IPAD.origin.x;
        contentViewOriginY = CONTENT_VIEW_FRAME_IPAD.origin.y;
        targetVcOriginX = targetVc == self.todoListViewController ? 0 : self.scroller.bounds.size.width/2;
    }
    CGPoint destinationOnScreen = CGPointMake(destinationOnListView.CGPointValue.x+contentViewOriginX+targetVcOriginX, destinationOnListView.CGPointValue.y+self.scroller.frame.origin.y+contentViewOriginY);
    
    //CGPoint destinationOnScreen = CGPointMake(destinationOnListView.CGPointValue.x, destinationOnListView.CGPointValue.y+self.scroller.frame.origin.y);
    // mark the itemview not focused
    itemView.isFocused = NO;
    
    // animation!
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        itemView.center = destinationOnScreen;
        __layerInvisibleDismissFocusedToDo.alpha = 0.0;
        [self __makeContentViewNormal];
        
        // make add button bg color normal
        self.addBtn.backgroundColor = CREATION_BUTTON_BG_COLOR_PLUS;
    } completion:^(BOOL finished) {
        [__layerInvisibleDismissFocusedToDo removeFromSuperview];
        __layerInvisibleDismissFocusedToDo = nil;
        
        // put back the itemView into its parent cell.
        [targetVc putBackItemViewIntoParentCell:itemView];
    }];
    
    // make add button +
    [self.addBtn makePlus];
}

-(void)forceToDismissFocusModeWithCompletionBlock:(void (^)())completionBlock
{
    // dismiss ui elements used for todo focus.
    [UIView animateWithDuration:0.3 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        __layerInvisibleDismissFocusedToDo.alpha = 0.0;
        [self __makeContentViewNormal];
        
        // make add button bg color normal
        self.addBtn.backgroundColor = CREATION_BUTTON_BG_COLOR_PLUS;
    } completion:^(BOOL finished) {
        [__layerInvisibleDismissFocusedToDo removeFromSuperview];
        __layerInvisibleDismissFocusedToDo = nil;
    }];
    
    // make add button +
    [self.addBtn makePlus];

}

-(void)moveToDo:(MDToDoObject *)todo sourceListType:(MDActiveListType)sourceListType targetListType:(MDActiveListType)targetListType flyOverAnimation:(BOOL)flyOverAni completionBlock:(void (^)())completionBlock
{
    
    MDToDoListViewController *sourceView = sourceListType == MDActiveListTypeToDo ? self.todoListViewController : self.doneListViewController;
    MDToDoListViewController *targetView = targetListType == MDActiveListTypeToDo ? self.todoListViewController : self.doneListViewController;
    
    if (flyOverAni == NO) {
        [sourceView removeToDoCellWithToDoObject:todo animated:YES completionBlock:^{
            [targetView insertNewToDoCellWithToDoObject:todo animated:YES];
        }];
        
        if (completionBlock) {
            completionBlock();
        }
        return;
        
    }
    
    // do fly over ani.
    
    // 1. take itemView out of sourceListView, and put it on transition layer (self.view)
    __block MDToDoItemView *itemView = [sourceView todoItemViewForToDoObject:todo];
    if (itemView == nil) {
        NSLog(@"[MDBaseViewController] could not find itemView from sourceView.");
        return;
    }
    CGPoint centerOnScreen = [itemView convertPoint:CGPointMake(CGRectGetWidth(itemView.bounds)/2, CGRectGetHeight(itemView.bounds)/2) toView:self.view];
    itemView.center = centerOnScreen;
    [self.view addSubview:itemView];
    
    // 2. disconnect link to the parent cell. the itemview is now really free!
    [sourceView makeItemViewFreeFromParentCell:itemView];
    
        // 3. calc destination position
        CGFloat destCenterX = targetListType == MDActiveListTypeDone ? CGRectGetWidth(self.view.bounds)*1.5 : -CGRectGetWidth(self.view.bounds)*0.5;
        CGPoint destCenterOnScreen = CGPointMake(destCenterX , self.todoListViewController.view.frame.origin.y+px2p(300));
        
        // 4. do animation. At the same time, create new cell on targetlist view with the todo data.
        [targetView insertNewToDoCellWithToDoObject:todo animated:YES];
        [[MDAppControl sharedInstance] blockEntireUI];
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            // make __contentView smaller
            [self __makeContentViewFarAway];
            // push back
            itemView.center = CGPointMake(centerOnScreen.x, centerOnScreen.y+px2p(100));
        } completion:^(BOOL finished) {
            
                // throw out
                [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
                    itemView.center = destCenterOnScreen;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.2 delay:0.0 usingSpringWithDamping:0.8 initialSpringVelocity:1.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                        // make __contentView normal
                        [self __makeContentViewNormal];
                    } completion:^(BOOL finished) {
                        // 5. remove cell from source view
                        [sourceView removeToDoCellWithToDoObject:todo animated:YES completionBlock:^{
                            
                        }];
                        // 6. we created new itemView. old itemView we can throw away
                        [itemView removeFromSuperview];
                        itemView = nil;
                        [[MDAppControl sharedInstance] unblockEntireUI];
                    }];
                    
                }];
            
        }];
    

}



@end
