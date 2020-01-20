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
@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, strong) UIActivityIndicatorView *activityView;
@end

// play status:play
static NSString * const kPlayStatusPlay = @"kPlayStatusPlay";
// play status:pause
static NSString * const kPlayStatusPause = @"kPlayStatusPause";

@implementation WWPlayer
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        [self pSetupPlayer];
        [self pSetupPlayerBar];
        [self pSetupTapAction];
        [self pSetupActivity];
    }
    return self;
}

// MARK: private methods
/**
 * @description setup player
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)pSetupPlayer {
    //http://cdn5.hd.etiantian.net/616d59dd8830d7b200a4a711062b9b89/5E257B44/etthd/msgz002041/400.mp4
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"http://cdn5.hd.etiantian.net/616d59dd8830d7b200a4a711062b9b89/5E257B44/etthd/msgz002041/400.mp4"]];
    self.avPlayer = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    
    AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    layer.videoGravity = AVLayerVideoGravityResizeAspect;
    layer.frame = self.bounds;
    [self.layer addSublayer:layer];
    
    // 监听播放状态
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓冲进度
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓冲是否为空
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓冲是否可以播放
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

/**
 * @description observe play status
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItemStatus currentStatus = [change[NSKeyValueChangeNewKey]integerValue];
        switch (currentStatus) {
            case AVPlayerItemStatusReadyToPlay:
                self.isReady = true;
                NSLog(@"可以播放了");
                break;
                
            default:
                self.isReady = false;
                NSLog(@"不可以播放");
                break;
        }
    } else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSArray *array = self.avPlayer.currentItem.loadedTimeRanges;
        if (array.count > 0) {
            // 本次缓冲时间范围
            CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];
            float startSeconds = CMTimeGetSeconds(timeRange.start);
            float durationSeconds = CMTimeGetSeconds(timeRange.duration);
            
            NSLog(@"startSeconds:%f,durationSeconds:%f",startSeconds,durationSeconds);
        }
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        NSLog(@"正在加载");
        if (self.activityView) {
            [self.activityView startAnimating];
        }
    } else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]) {
        NSLog(@"加载的内容可以播放了");
        if (self.activityView) {
            [self.activityView stopAnimating];
        }
    }
}

/**
* @description setup player bar
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)pSetupPlayerBar {
    self.playerBar = [[WWPlayerBar alloc]initWithFrame:CGRectMake(0, self.bounds.size.height - 50, self.bounds.size.width, 50)];
    self.playerBar.delegate = self;
    [self addSubview:self.playerBar];
}

/**
* @description setup player tap action
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)pSetupTapAction {
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapActionCallBack)];
    [self addGestureRecognizer:tapGes];
    [self pHiddenPlayerBar];
}

- (void)tapActionCallBack {
    self.playerBar.hidden = !self.playerBar.hidden;
    [self pHiddenPlayerBar];
}

/**
* @description player hidden 
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)pHiddenPlayerBar {
    // 如果没有隐藏 过 3s 自动隐藏
    if (!self.playerBar.hidden) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.playerBar.hidden = true;
        });
    }
}

/**
* @description activity view 
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)pSetupActivity {
    self.activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    NSLog(@"self.centerX:%f  self.centerY:%f",self.center.x,self.center.y);
    self.activityView.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    [self addSubview:self.activityView];
}

// MARK: public methods
- (void)play {
    if (self && self.avPlayer) {
        [self.avPlayer play];
    } else {
        NSLog(@"播放遇到问题");
    }
}

- (void)pause {
    if (self && self.avPlayer) {
        [self.avPlayer pause];
    } else {
        NSLog(@"暂停遇到问题");
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
    if (info) {
        NSString *playStatus = info[@"playStatus"];
        if ([playStatus isEqualToString:kPlayStatusPlay]) {
            [self pause];
        } else {
            [self play];
        }
    } else {
        NSLog(@"播放按钮回调数据有问题");
    }
}

/**
* @description dealloc resource
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)dealloc {
    if (self.avPlayer) {
        [self.avPlayer pause];
        self.avPlayer = nil;
    }
    
    if (self.activityView) {
        self.activityView = nil;
    }
    
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"status"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.avPlayer.currentItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

@end




// MARK: Player Bar
@interface WWPlayerBar()
@property (nonatomic, strong) UIButton *playButton;
@end

@implementation WWPlayerBar
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor orangeColor]colorWithAlphaComponent:0.3];
        [self pSetupSubviews];
    }
    return self;
}

/**
 * @description init subviews
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)pSetupSubviews {
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(20, 0, 50, 50)];
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
        NSString *playStatus = self.playButton.selected ? kPlayStatusPause : kPlayStatusPlay;
        [self.delegate dTappedPlayButton:@{@"playStatus":playStatus}];
    }
}


@end
