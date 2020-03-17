//
//  AppDelegate.m
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import "AppDelegate.h"
@import AppCenter;
@import AppCenterAnalytics;
@import AppCenterCrashes;

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MSAppCenter start:@"196e96d5-d25f-48a5-885e-37d6ce066f0b" withServices:@[
      [MSAnalytics class],
      [MSCrashes class]
    ]];
    return YES;
}


#pragma mark - UISceneSession lifecycle


- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options {
    // Called when a new scene session is being created.
    // Use this method to select a configuration to create the new scene with.
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}


- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions {
    // Called when the user discards a scene session.
    // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
    // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
}


@end
