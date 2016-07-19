//
//  TableRidingView.h
//  cycleLife2-1
//
//  Created by 曹鹏旭 on 16/4/11.
//  Copyright © 2016年 曹鹏旭. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableRidingView : UIView
@property (weak, nonatomic) IBOutlet UIButton *turnBtn;
@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *suspendBtn;
@property (weak, nonatomic) IBOutlet UIButton *endBtn;
@property (weak, nonatomic) IBOutlet UILabel *speedL;
@property (weak, nonatomic) IBOutlet UILabel *timeL;
@property (weak, nonatomic) IBOutlet UILabel *distanceL;
@property (weak, nonatomic) IBOutlet UILabel *kcalL;
@property (weak, nonatomic) IBOutlet UILabel *maxSpeedL;
- (void)startBtnClick;  // 开始
- (void)suspendBtnClick;  // 暂停
- (void)endBtnClick;  // 完成
@end
