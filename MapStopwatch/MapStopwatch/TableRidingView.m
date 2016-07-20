//
//  TableRidingView.m
//  cycleLife2-1
//
//  Created by 曹鹏旭 on 16/4/11.
//  Copyright © 2016年 曹鹏旭. All rights reserved.
//

#import "TableRidingView.h"

@interface TableRidingView ()
{
    BOOL _judgeSuspend;  // 是否暂停
}
@end



@implementation TableRidingView

- (void)startBtnClick
{
    self.startBtn.hidden = YES;
    self.suspendBtn.hidden = NO;
    self.endBtn.hidden = NO;
}
- (void)suspendBtnClick
{
    if (!_judgeSuspend)
    {
        _judgeSuspend = YES;
        [self.suspendBtn setTitle:@"继续" forState:UIControlStateNormal];
    }
    else
    {
        _judgeSuspend = NO;
        [self.suspendBtn setTitle:@"暂停" forState:UIControlStateNormal];
    }
}
- (void)endBtnClick
{
    self.startBtn.hidden = NO;
    self.suspendBtn.hidden = YES;
    self.endBtn.hidden = YES;
    
    self.speedL.text = @"0.00";
    self.timeL.text = @"00:00:00";
    self.distanceL.text = @"0.00";
    self.kcalL.text = @"0.00";
    self.maxSpeedL.text = @"0.00";
}



@end


