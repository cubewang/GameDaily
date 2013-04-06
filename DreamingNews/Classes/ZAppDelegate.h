//
//  ZAppDelegate.h
//  Dreaming
//
//  Created by cg on 12-9-28.
//  Copyright (c) 2012年 Dreaming Team. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "MBProgressHUD.h"
#import "VoteView.h"
#import "MainViewController.h"
#import "MainViewController_iPad.h"

#define kLastUpdateDate  @"lastUpdateDate"

@interface ZAppDelegate : UIResponder <UIApplicationDelegate> {
    
}

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, retain) MBProgressHUD *HUD;

@property (nonatomic, assign) UIBackgroundTaskIdentifier oldTaskId;

@property (nonatomic, assign) id<AutoRefreshingDelegate> autoRefreshingDelegate;

@property (nonatomic, retain) CLLocation *userLocation;

+ (ZAppDelegate *)sharedAppDelegate;
- (void)showNetworkFailed:(UIView *)view;
- (void)showInformation:(UIView *)view info:(NSString *)info;

- (void)showProgress:(UIView *)view info:(NSString *)info;
- (void)setProgress:(UIView *)view progress:(float)progress info:(NSString *)info;


+ (UILabel*)createNavTitleView:(NSString *)title;


@end
