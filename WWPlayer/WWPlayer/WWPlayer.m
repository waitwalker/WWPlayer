//
//  WWPlayer.m
//  WWPlayer
//
//  Created by etiantian on 2020/1/20.
//  Copyright © 2020 etiantian. All rights reserved.
//

#import "WWPlayer.h"
#import <AVFoundation/AVFoundation.h>
@interface WWPlayer()<WWPlayerBarDelegate>
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
    self.playerBar.delegate = self;
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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

// MARK: play bar delegate 回调

/**
 * @description 播放按钮点击回调
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)dTappedPlayButton:(NSDictionary *)info {
    
}

@end




// MARK: Player Bar
@interface WWPlayerBar()
@property (nonatomic, strong) UIButton *playButton;


@end

@implementation WWPlayerBar

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self pSetupSubviews];
    }
    return self;
}

- (void)pSetupSubviews {
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(30, 0, 50, 50)];
    [self.playButton setTitle:@"播" forState:UIControlStateNormal];
    [self.playButton setBackgroundColor:[UIColor greenColor]];
    [self.playButton addTarget:self action:@selector(playButtonActionCallBack:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
}

- (void)playButtonActionCallBack:(UIButton *)button {
    self.playButton.selected = !self.playButton.selected;
    if (self.playButton.selected) {
        [button setTitle:@"停" forState:UIControlStateNormal];
    } else {
        [button setTitle:@"播" forState:UIControlStateNormal];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(dTappedPlayButton:)]) {
        NSString *playStatus = self.playButton.selected ? @"pause" : @"play";
        [self.delegate dTappedPlayButton:@{@"playStatus":playStatus}];
    }
}


@end
