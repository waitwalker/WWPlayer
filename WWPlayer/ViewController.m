//
//  ViewController.m
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import "ViewController.h"
#import "WWPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    WWPlayer *player = [[WWPlayer alloc]initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 300) url:@""];
    [self.view addSubview:player];
}


@end
