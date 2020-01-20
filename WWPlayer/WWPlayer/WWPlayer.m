//
//  WWPlayer.m
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import "WWPlayer.h"
#import <AVFoundation/AVFoundation.h>
@interface WWPlayer()
@property (nonatomic, strong) WWPlayerBar *playerBar;
@property (nonatomic, strong) AVPlayer *avPlayer;

@end

@implementation WWPlayer

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        [self pSetupPlayer];
        [self pSetupPlayerBar];
        [self pSetupTapAction];
    }
    return self;
}

- (void)pSetupPlayer {
    //http://cdn5.hd.etiantian.net/616d59dd8830d7b200a4a711062b9b89/5E257B44/etthd/msgz002041/400.mp4
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"http://cdn5.hd.etiantian.net/616d59dd8830d7b200a4a711062b9b89/5E257B44/etthd/msgz002041/400.mp4"]];
    self.avPlayer = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    layer.frame = self.bounds;
    [self.layer addSublayer:layer];
    [self.avPlayer play];
}

- (void)pSetupPlayerBar {
    self.playerBar = [[WWPlayerBar alloc]initWithFrame:CGRectMake(0, self.bounds.size.height - 50, self.bounds.size.width, 50)];
    self.playerBar.backgroundColor = [UIColor redColor];
    [self addSubview:self.playerBar];
}

- (void)pSetupTapAction {
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapActionCallBack)];
    [self addGestureRecognizer:tapGes];
    [self pHiddenPlayerBar];
}

- (void)tapActionCallBack {
    self.playerBar.hidden = !self.playerBar.hidden;
    [self pHiddenPlayerBar];
}

- (void)pHiddenPlayerBar {
    // 如果没有隐藏 过 3s 自动隐藏
    if (!self.playerBar.hidden) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.playerBar.hidden = true;
        });
    }
}

- (void)dealloc {
    if (self.avPlayer) {
        [self.avPlayer pause];
        self.avPlayer = nil;
    }
}

@end


@interface WWPlayerBar()

@end

@implementation WWPlayerBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}


@end
