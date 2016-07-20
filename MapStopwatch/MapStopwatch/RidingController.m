//
//  RidingController.m
//  cycleLife2-1
//
//  Created by 曹鹏旭 on 16/4/11.
//  Copyright © 2016年 曹鹏旭. All rights reserved.
//

#import "RidingController.h"
#import "TableRidingView.h"
#import "MapRidingView.h"

#define __ScreenWidth    [[UIScreen mainScreen] bounds].size.width
#define __ScreenHeight   [[UIScreen mainScreen] bounds].size.height

@interface RidingController ()
{
    BOOL _judgeSuspend;  // 暂停or开始
    BOOL _judgeRiding;  // 是否开始骑行
}
@property (weak, nonatomic) IBOutlet UIScrollView *mainScroll;
@property (nonatomic, strong) MapRidingView *mapRidingView;
@property (nonatomic, strong) TableRidingView *tableRidingView;
@property (nonatomic, strong) NSTimer *secondTimer;
@end



@implementation RidingController

#pragma mark === viewDidLoad
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mainScroll.contentSize = CGSizeMake(2 * __ScreenWidth, 0);
    [self.mainScroll setContentOffset:CGPointMake(0, 0)];
    
    // 创建TableView和MapView
    [self addTableAndMap];
    
    // 把地图先加载好
    [_mapRidingView mapStart];
    
    // 开始定位
    [_mapRidingView locationStart];
    
    // 1秒后停止定位
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [_mapRidingView.locService stopUserLocationService];
    });
}



#pragma mark === 加载TableView和MapView
- (void)addTableAndMap
{
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"TableRiding" owner:nil options:nil];
    _tableRidingView = [nib lastObject];
    _tableRidingView.suspendBtn.hidden = YES;
    _tableRidingView.endBtn.hidden = YES;
    
    [_tableRidingView.turnBtn addTarget:self action:@selector(oneTurnBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_tableRidingView.startBtn addTarget:self action:@selector(startBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_tableRidingView.suspendBtn addTarget:self action:@selector(suspendBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [_tableRidingView.endBtn addTarget:self action:@selector(endBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _tableRidingView.frame = CGRectMake(0, 0, self.mainScroll.frame.size.width, self.mainScroll.frame.size.height);
    [self.mainScroll addSubview:_tableRidingView];
    
    
    NSArray *mapNib = [[NSBundle mainBundle] loadNibNamed:@"MapRiding" owner:nil options:nil];
    _mapRidingView = [mapNib lastObject];
    [_mapRidingView.turnBtn addTarget:self action:@selector(twoTurnBtnClick) forControlEvents:UIControlEventTouchUpInside];
    _mapRidingView.frame = CGRectMake(__ScreenWidth, 0, self.mainScroll.frame.size.width, self.mainScroll.frame.size.height);
    [self.mainScroll addSubview:_mapRidingView];
}



#pragma mark === 跳转到地图页
- (void)oneTurnBtnClick
{
    [self.mainScroll setContentOffset:CGPointMake(__ScreenWidth, 0) animated:YES];
    
    if (!_judgeRiding)  // 没有开始骑行
    {
        // 开始定位
        [_mapRidingView locationStart];
    }
}
#pragma mark === 返回到码表页
- (void)twoTurnBtnClick
{
    [self.mainScroll setContentOffset:CGPointMake(0, 0) animated:YES];
    
    if (!_judgeRiding)  // 没有开始骑行
    {
        // 停止定位
        [_mapRidingView.locService stopUserLocationService];
    }
}



#pragma mark === 开始骑行
- (void)startBtnClick
{
    _judgeRiding = YES;
    
    // 开始定位
    [_mapRidingView locationStart];
    
    [_tableRidingView startBtnClick];
    [_mapRidingView startBtnClick];
    
    self.secondTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(syncDate) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.secondTimer forMode:NSRunLoopCommonModes];
}
#pragma mark === 同步数据
- (void)syncDate
{
    _tableRidingView.speedL.text = _mapRidingView.speedL.text;
    _tableRidingView.timeL.text = _mapRidingView.timeL.text;
    _tableRidingView.distanceL.text = _mapRidingView.distanceL.text;
    _tableRidingView.kcalL.text = _mapRidingView.kcalL.text;
    _tableRidingView.maxSpeedL.text = _mapRidingView.maxSpeedL.text;
}
#pragma mark === 暂停or开始
- (void)suspendBtnClick
{
    [_tableRidingView suspendBtnClick];
    [_mapRidingView suspendBtnClick];
    
    if (!_judgeSuspend)
    {
        //暂停骑行
        _judgeSuspend = YES;
        _judgeRiding = NO;
        
        [self.secondTimer invalidate];//定时器暂停
    }
    else
    {
        //继续骑行
        _judgeSuspend = NO;
        _judgeRiding = YES;
        
        self.secondTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(syncDate) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.secondTimer forMode:NSRunLoopCommonModes];
    }
}



#pragma mark === 结束骑行
- (void)endBtnClick
{
    _judgeRiding = NO;
    
    [_tableRidingView endBtnClick];
    [_mapRidingView endBtnClick];
    [self.secondTimer invalidate];
}



@end


