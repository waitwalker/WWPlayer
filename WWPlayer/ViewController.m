//
//  ViewController.m
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import "ViewController.h"
#import "WWPlayer.h"

@interface ViewController ()<WWPlayerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //http://cdn5.hd.etiantian.net/616d59dd8830d7b200a4a711062b9b89/5E257B44/etthd/msgz002041/400.mp4
    //http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4
    //http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4
    WWPlayer *player = [[WWPlayer alloc]initWithFrame:CGRectMake(0, 100, [UIScreen mainScreen].bounds.size.width, 300) url:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    player.delegate = self;
    [self.view addSubview:player];
}

// MARK: - WWPlayerDelegate call back
- (void)playerDidError:(NSDictionary *)info {

}

@end
