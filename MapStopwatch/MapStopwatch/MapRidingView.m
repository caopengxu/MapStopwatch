//
//  MapRidingView.m
//  cycleLife2-1
//
//  Created by 曹鹏旭 on 16/4/11.
//  Copyright © 2016年 曹鹏旭. All rights reserved.
//

#import "MapRidingView.h"
#import "Masonry.h"
#define __JudgeDistance 35  // 定位的最小更新距离、间接限制定位的速率
#define __IntervalTimer 2.0  // 定时器获取定位信息的间隔

@interface MapRidingView () <BMKLocationServiceDelegate, BMKMapViewDelegate>
{
    NSInteger _i;  // location[]
    BOOL _mapStartOnce;  // 地图只加载一次
    BOOL _drawLineOnce;  // 第一次不用设置第一个点，也不进行划线
    BOOL _startDrawLine;  // 开始划线，只执行一次
    BOOL _judgeLocationOnce;  // 开始存储数据后第一次定位
    BOOL _intervalLocation;  // 间隔获取地理位置
    BOOL _judgeSuspend;  // 暂停or开始
//    NSInteger _judgeTimes;  // 三次大于特定距离记录数据
    NSInteger _judgeSpeedZero;  // 判断速度是否清零
    NSInteger _judgeSpeedOne;  // 判断速度是否清零
    NSInteger _judgeSpeedTwo;  // 判断速度是否清零
    NSInteger _locationLadder;  // 记录地图点逐渐增加
    BOOL _judgeIsRiding;  // 判断是否开始骑行
    double _intervalTimeOne;  // 在定时器间隔时间内第一次定位的时间
    double _intervalTimeTwo;  // 在定时器间隔时间内最后一次定位的时间
}
@property (nonatomic, strong) BMKMapView *myMapView;
@property (nonatomic, assign) CLLocationCoordinate2D *locations;
@property (nonatomic, assign) CLLocationCoordinate2D *oneLocations;
@property (nonatomic, assign) CLLocationCoordinate2D myLocation;
@property (nonatomic, assign) CLLocationCoordinate2D start2D;
@property (nonatomic, assign) CLLocationCoordinate2D end2D;
@property (nonatomic, assign) double sumDistance;
@property (nonatomic, assign) double sumKcal;
@property (nonatomic, assign) double sumTime;
@property (nonatomic, assign) double sumCalorie;
@property (nonatomic, assign) int secondsCountDown;
@property (nonatomic, strong) NSDate *onceDate;
//@property (nonatomic, assign) double speedDistance;
@property (nonatomic, assign) double lastTimeSpeed;
@property (nonatomic, strong) NSMutableArray *locationArray;
@end



@implementation MapRidingView

#pragma mark === 懒加载
- (BMKMapView *)myMapView
{
    if (!_myMapView)
    {
        _myMapView = [[BMKMapView alloc] init];
    }
    return _myMapView;
}
- (BMKLocationService *)locService
{
    if (!_locService)
    {
        _locService = [[BMKLocationService alloc] init];
    }
    return _locService;
}
- (CLLocationCoordinate2D *)locations
{
    if (!_locations)
    {
        _locations = malloc(100 * sizeof(CLLocationCoordinate2D));
    }
    return _locations;
}
- (CLLocationCoordinate2D *)oneLocations
{
    if (!_oneLocations)
    {
        _oneLocations = malloc(1 * sizeof(CLLocationCoordinate2D));
    }
    return _oneLocations;
}
- (UILabel *)maxSpeedL
{
    if (!_maxSpeedL)
    {
        _maxSpeedL = [[UILabel alloc] init];
    }
    return _maxSpeedL;
}
- (NSMutableArray *)locationArray
{
    if (!_locationArray)
    {
        _locationArray = [[NSMutableArray alloc] init];
    }
    return _locationArray;
}



#pragma mark === 地图初始化
- (void)mapStart
{
    if (!_mapStartOnce)
    {
        _mapStartOnce = YES;
        
        self.maxSpeedL.text = @"0.00";
        
        [self insertSubview:self.myMapView atIndex:0];
        
        [self.myMapView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.mas_top).offset(45);
            make.bottom.equalTo(self.mas_bottom);
            make.left.equalTo(self.mas_left);
            make.right.equalTo(self.mas_right);
        }];
        
        // 设置代理
        self.myMapView.delegate = self;
        //设置定位的状态
        self.myMapView.userTrackingMode = BMKUserTrackingModeNone;
        //显示定位图层
        self.myMapView.showsUserLocation = YES;
        
        
        //设置定位图层自定义样式
        BMKLocationViewDisplayParam *userlocationStyle = [[BMKLocationViewDisplayParam alloc] init];
        //精度圈是否显示
        userlocationStyle.isRotateAngleValid = YES;
        //跟随态旋转角度是否生效
        userlocationStyle.isAccuracyCircleShow = NO;
        //定位图标
        //    userlocationStyle.locationViewImgName = [UIImage imageNamed:@"图标名称"];
        //更新参样式信息
        [_myMapView updateLocationViewWithParam:userlocationStyle];
    }
}
#pragma mark === 定位
- (void)locationStart
{
    if ([[UIDevice currentDevice].systemVersion doubleValue] >= 9)
    {
        self.locService.allowsBackgroundLocationUpdates = YES;
    }
    self.locService.delegate = self;
    _locService.distanceFilter = __JudgeDistance;
    _locService.desiredAccuracy = kCLLocationAccuracyBest;
    [self.locService startUserLocationService];
}



#pragma mark === 开始骑行
- (void)startBtnClick
{
    // 三秒后开始记录数据
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW,(int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        _judgeIsRiding = YES;
    });
    
    // 计时
    self.secondsCountDown = 0;
    self.reckonTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDownAction) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.reckonTimer forMode:NSRunLoopCommonModes];
}
#pragma mark === 暂停or开始
- (void)suspendBtnClick
{
    if (!_judgeSuspend)
    {
        _judgeSuspend = YES;
        
        [self.locService stopUserLocationService];
        [self.reckonTimer invalidate];
        
        [self.speedTimer setFireDate:[NSDate distantFuture]];
        [self.speedTimer invalidate];
    }
    else
    {
        _judgeSuspend = NO;
        
        [self.locService startUserLocationService];
        
        // 划线定时器
        self.speedTimer = [NSTimer timerWithTimeInterval:3.6 target:self selector:@selector(drawLineGo) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.speedTimer forMode:NSRunLoopCommonModes];
        
        // 计时
        [self.speedTimer setFireDate:[NSDate date]];
//        self.secondsCountDown = 0;
        self.reckonTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(countDownAction) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.reckonTimer forMode:NSRunLoopCommonModes];
    }
}
#pragma mark === 提交数据
- (void)endBtnClick
{
    self.locations = nil;
    _i = 0;
    _judgeIsRiding = NO;
    _startDrawLine = NO;
    _judgeLocationOnce = NO;
    
    [self.locService stopUserLocationService];
    [self.reckonTimer invalidate];
    [self.speedTimer invalidate];

    self.speedL.text = @"0.00";
    self.timeL.text = @"00:00:00";
    self.distanceL.text = @"0.00";
    self.kcalL.text = @"0.00";
    self.maxSpeedL.text = @"0.00";
}



#pragma mark === 计时
- (void)countDownAction
{
    self.secondsCountDown++;
    NSString *str_hour = [NSString stringWithFormat:@"%02d", _secondsCountDown/3600];
    NSString *str_minute = [NSString stringWithFormat:@"%02d", (_secondsCountDown%3600)/60];
    NSString *str_second = [NSString stringWithFormat:@"%02d", _secondsCountDown%60];
    NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@", str_hour, str_minute, str_second];
    self.timeL.text = [NSString stringWithFormat:@"%@", format_time];
    
    // 同步数据
    if (self.completion)
    {
        self.completion();
    }
}
#pragma mark === 划线
- (void)drawLineGo
{
    if (_i > 1)  // _i等于1时说明只定位了一个点！！！
    {
        if (!_drawLineOnce)
        {
            _drawLineOnce = YES;
            
            // 划线
            CLLocationCoordinate2D *locations = malloc(_i * sizeof(CLLocationCoordinate2D));
            
            CLLocationDegrees minLat = 90.0;
            CLLocationDegrees maxLat = -90.0;
            CLLocationDegrees minLon = 180.0;
            CLLocationDegrees maxLon = -180.0;
            
            for (int j = 0; j < _i; j++)
            {
                CLLocationDegrees longitude = _locations[j].longitude;
                CLLocationDegrees latitude = _locations[j].latitude;
                
                minLat = MIN(minLat, latitude);
                maxLat = MAX(maxLat, latitude);
                minLon = MIN(minLon, longitude);
                maxLon = MAX(maxLon, longitude);
                
                locations[j] = CLLocationCoordinate2DMake(latitude, longitude);
            }
            
            BMKCoordinateSpan viewSapn;
            viewSapn.latitudeDelta = 0.005;
            viewSapn.longitudeDelta = 0.005;
            
            BMKCoordinateRegion viewRegion;
            viewRegion.center = self.myLocation;
            viewRegion.span = viewSapn;
            
            BMKPolyline* polyline = [BMKPolyline polylineWithCoordinates:locations count:_i];
            
            [self.myMapView setRegion:viewRegion animated:YES];
            [self.myMapView addOverlay:polyline];
            
            self.oneLocations[0] = self.locations[_i - 1];
            free(locations);
            _i = 1;
        }
        else
        {
            // 划线
            CLLocationCoordinate2D *locations = malloc((_i) * sizeof(CLLocationCoordinate2D));
            
            locations[0] = self.oneLocations[0];  // 获取上次划线的最后一个点
            
            CLLocationDegrees minLat = 90.0;
            CLLocationDegrees maxLat = -90.0;
            CLLocationDegrees minLon = 180.0;
            CLLocationDegrees maxLon = -180.0;
            
            for (int j = 1; j < _i; j++)
            {
                CLLocationDegrees longitude = _locations[j].longitude;
                CLLocationDegrees latitude = _locations[j].latitude;
                
                minLat = MIN(minLat, latitude);
                maxLat = MAX(maxLat, latitude);
                minLon = MIN(minLon, longitude);
                maxLon = MAX(maxLon, longitude);
                
                locations[j] = CLLocationCoordinate2DMake(latitude, longitude);
            }
            
            BMKCoordinateRegion viewRegion;
            viewRegion.center = self.myLocation;
            viewRegion.span = self.myMapView.region.span;
            
            BMKPolyline* polyline = [BMKPolyline polylineWithCoordinates:locations count:_i];
            
            [self.myMapView setRegion:viewRegion animated:YES];
            [self.myMapView addOverlay:polyline];
            
            //    dispatch_async(dispatch_get_main_queue(), ^{
            //
            //        [self.myMapView setRegion:viewRegion animated:YES];
            //        [self.myMapView addOverlay:polyline];
            //    });
            
            self.oneLocations[0] = self.locations[_i - 1];
            free(locations);
            _i = 1;
        }
    }
}



#pragma mark === Location代理方法
- (void)didUpdateBMKUserLocation:(BMKUserLocation *)userLocation
{
    NSLog(@"-----------------lat %f,long %f", userLocation.location.coordinate.latitude, userLocation.location.coordinate.longitude);
    
    // 定位
    [self.myMapView updateLocationData:userLocation];
    self.myLocation = userLocation.location.coordinate;
    
    if (!_judgeIsRiding)
    {
        // 定位范围
        BMKCoordinateSpan viewSapn;
        viewSapn.latitudeDelta = 0.005;
        viewSapn.longitudeDelta = 0.005;
        BMKCoordinateRegion viewRegion;
        viewRegion.center = userLocation.location.coordinate;
        viewRegion.span = viewSapn;
        [self.myMapView setRegion:viewRegion animated:YES];
    }
    
    if (_judgeIsRiding)
    {
        // 存储坐标信息（划线）
        self.locations[_i] = userLocation.location.coordinate;
        _i++;
        
        // 存储坐标信息（上传）
        _locationLadder++;
        NSDictionary *roadBook = @{@"longitude":@(userLocation.location.coordinate.longitude), @"latitude":@(userLocation.location.coordinate.latitude), @"coordinatesDate":@(_locationLadder)};
        [self.locationArray addObject:roadBook];
        
        if (!_startDrawLine)
        {
            _startDrawLine = YES;
            
            // 划线定时器
            self.speedTimer = [NSTimer timerWithTimeInterval:__IntervalTimer target:self selector:@selector(drawLineGo) userInfo:nil repeats:YES];
            [[NSRunLoop currentRunLoop] addTimer:self.speedTimer forMode:NSRunLoopCommonModes];
        }
        
        if (!_judgeLocationOnce)
        {
            _judgeLocationOnce = YES;
            
            self.start2D = userLocation.location.coordinate;
            
            // 第一次的时间
            self.onceDate = self.reckonTimer.fireDate;
            
            NSDate *datenow = [NSDate date];
            NSTimeZone *zone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
            NSInteger interval = [zone secondsFromGMTForDate:datenow];
            NSDate *localeDate = [datenow dateByAddingTimeInterval:interval];
            NSString *timeSp = [NSString stringWithFormat:@"%f", [localeDate timeIntervalSince1970]];
            _intervalTimeOne = [timeSp doubleValue];
        }
        else
        {
            if (!_intervalLocation)
            {
                _intervalLocation = YES;
                self.end2D = userLocation.location.coordinate;
                
                // 距离、速度、最大速度、卡路里
                BMKMapPoint mp1 = BMKMapPointForCoordinate(self.start2D);
                BMKMapPoint mp2 = BMKMapPointForCoordinate(self.end2D);
                CLLocationDistance distance = BMKMetersBetweenMapPoints(mp1, mp2);
//                _speedDistance = distance;
                _sumDistance += distance;
                self.distanceL.text = [NSString stringWithFormat:@"%.2f", _sumDistance / 1000];
                
                NSDate *datenow = [NSDate date];
                NSTimeZone *zone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
                NSInteger interval = [zone secondsFromGMTForDate:datenow];
                NSDate *localeDate = [datenow dateByAddingTimeInterval:interval];
                NSString *timeSp = [NSString stringWithFormat:@"%f", [localeDate timeIntervalSince1970]];
                _intervalTimeTwo = [timeSp doubleValue];
                double intervalTime = _intervalTimeTwo - _intervalTimeOne;
                double speed = (distance / 1000) / (intervalTime / 3600);
                self.speedL.text = [NSString stringWithFormat:@"%.2f", speed];
                
                if (speed > _lastTimeSpeed)
                {
                    _lastTimeSpeed = speed;
                    self.maxSpeedL.text = [NSString stringWithFormat:@"%.2f", _lastTimeSpeed];
                }
                
                // 消耗的卡路里（kcal）= 时速(km/h)×体重(kg)×1.05×运动时间(h)
                double kcal = speed * 60 * 1.05 * (intervalTime / 3600);
                _sumKcal += kcal;
                self.kcalL.text = [NSString stringWithFormat:@"%.0f", _sumKcal];
            }
            else
            {
                _intervalLocation = NO;
                
                self.start2D = userLocation.location.coordinate;
                
                BMKMapPoint mp1 = BMKMapPointForCoordinate(self.start2D);
                BMKMapPoint mp2 = BMKMapPointForCoordinate(self.end2D);
                CLLocationDistance distance = BMKMetersBetweenMapPoints(mp1, mp2);
//                _speedDistance = distance;
                _sumDistance += distance;
                self.distanceL.text = [NSString stringWithFormat:@"%.2f", _sumDistance / 1000];
                
                NSDate *datenow = [NSDate date];
                NSTimeZone *zone = [NSTimeZone timeZoneWithName:@"Asia/Shanghai"];
                NSInteger interval = [zone secondsFromGMTForDate:datenow];
                NSDate *localeDate = [datenow dateByAddingTimeInterval:interval];
                NSString *timeSp = [NSString stringWithFormat:@"%f", [localeDate timeIntervalSince1970]];
                _intervalTimeOne = [timeSp doubleValue];
                double intervalTime = _intervalTimeOne - _intervalTimeTwo;
                double speed = (distance / 1000) / (intervalTime / 3600);
                self.speedL.text = [NSString stringWithFormat:@"%.2f", speed];
                if (speed > _lastTimeSpeed)
                {
                    _lastTimeSpeed = speed;
                    self.maxSpeedL.text = [NSString stringWithFormat:@"%.2f", _lastTimeSpeed];
                }
                
                double kcal = speed * 60 * 1.05 * (intervalTime / 3600);
                _sumKcal += kcal;
                self.kcalL.text = [NSString stringWithFormat:@"%.2f", _sumKcal];
            }
        }
    }
}
#pragma mark === Map代理方法
- (BMKOverlayView *)mapView:(BMKMapView *)mapView viewForOverlay:(id<BMKOverlay>)overlay
{
    if ([overlay isKindOfClass:[BMKPolyline class]])
    {
        BMKPolylineView* polylineView = [[BMKPolylineView alloc] initWithOverlay:overlay];
        polylineView.strokeColor = [[UIColor purpleColor] colorWithAlphaComponent:1];
        polylineView.lineWidth = 5.0;
        return polylineView;
    }
    
    return nil;
}



#pragma mark === 界面消失时
- (void)dealloc
{
    [_reckonTimer fire];
    
    [_myMapView viewWillDisappear];
    [_locService stopUserLocationService];
    _locService.delegate = nil;
    _myMapView.delegate = nil;
    
    if (_myMapView)
    {
        _myMapView = nil;
    }
}



@end


