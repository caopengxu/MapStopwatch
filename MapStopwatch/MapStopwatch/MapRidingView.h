//
//  MapRidingView.h
//  cycleLife2-1
//
//  Created by 曹鹏旭 on 16/4/11.
//  Copyright © 2016年 曹鹏旭. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <BaiduMapAPI_Map/BMKMapComponent.h>
#import <BaiduMapAPI_Location/BMKLocationComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>

@interface MapRidingView : UIView
@property (weak, nonatomic) IBOutlet UIButton *turnBtn;
@property (weak, nonatomic) IBOutlet UILabel *speedL;
@property (weak, nonatomic) IBOutlet UILabel *timeL;
@property (weak, nonatomic) IBOutlet UILabel *distanceL;
@property (weak, nonatomic) IBOutlet UILabel *kcalL;
@property (nonatomic, strong) BMKLocationService *locService;
@property (nonatomic,strong) UILabel *maxSpeedL;
@property (nonatomic, strong) NSTimer *reckonTimer;
@property (nonatomic, strong) NSTimer *speedTimer;
- (void)startBtnClick;  // 开始
- (void)suspendBtnClick;  // 暂停
- (void)endBtnClick;  // 完成
- (void)mapStart;
- (void)locationStart;
@property (nonatomic, strong) void (^completion) ();
@end
