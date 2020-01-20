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
    
    // 当前播放时间监听
    __weak __typeof(self) weakSelf = self;
    [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
        __strong __typeof(weakSelf) strongSelf = weakSelf; 
        NSLog(@"current thread:%@",[NSThread currentThread]);
        NSInteger currentTime = strongSelf.avPlayer.currentItem.currentTime.value / strongSelf.avPlayer.currentItem.currentTime.timescale;
        NSInteger durationTime = strongSelf.avPlayer.currentItem.duration.value / strongSelf.avPlayer.currentItem.duration.timescale;
        NSLog(@"当前播放时间:%ld 总的播放时间:%ld",(long)currentTime,(long)durationTime);
        strongSelf.playerBar.currentTime = currentTime;
        strongSelf.playerBar.totalDuration = durationTime;
    }];
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
            float loadedDurationSeconds = CMTimeGetSeconds(timeRange.duration);
            NSLog(@"start load seconds:%f,duration load seconds:%f",startSeconds,loadedDurationSeconds);
            self.playerBar.totalLoadedTime = loadedDurationSeconds;
            NSInteger durationTime = self.avPlayer.currentItem.duration.value / self.avPlayer.currentItem.duration.timescale;
            self.playerBar.totalDuration = durationTime;
            
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
@property (nonatomic, strong) UIView *progressContainerView;
@property (nonatomic, strong) UIView *loadedView;
@property (nonatomic, strong) UIView *playedView;
@property (nonatomic, strong) UIImageView *idotImageView;
@end

@implementation WWPlayerBar
// MARK: 成员变量声明
@synthesize totalDuration = _totalDuration;
@synthesize currentTime = _currentTime;
@synthesize totalLoadedTime = _totalLoadedTime;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor orangeColor]colorWithAlphaComponent:0.3];
        [self pSetupSubviews];
    }
    return self;
}

// MARK: setter
- (void)setTotalDuration:(NSInteger)totalDuration {
    _totalDuration = totalDuration;
}

- (NSInteger)totalDuration {
    return _totalDuration;
}

- (void)setTotalLoadedTime:(float)totalLoadedTime {
    _totalLoadedTime = totalLoadedTime;
    if (_totalDuration > 0) {
        self.loadedView.frame = CGRectMake(self.progressContainerView.frame.origin.x, self.progressContainerView.frame.origin.y, (totalLoadedTime / self.totalDuration) * self.progressContainerView.bounds.size.width, self.progressContainerView.frame.size.height);
    }
}

- (float)totalLoadedTime {
    return _totalLoadedTime;
}

- (void)setCurrentTime:(NSInteger)currentTime {
    _currentTime = currentTime;
    if (_totalDuration > 0) {

        CGFloat progress = ((CGFloat)currentTime / (CGFloat)self.totalDuration);
        CGFloat width = progress * self.progressContainerView.frame.size.width;
        self.playedView.frame = CGRectMake(self.progressContainerView.frame.origin.x, self.progressContainerView.frame.origin.y, width, self.progressContainerView.frame.size.height);
        self.idotImageView.frame = CGRectMake(self.progressContainerView.frame.origin.x + width - 15, self.progressContainerView.frame.origin.y - 10, 30, 30);
    }
}

- (NSInteger)currentTime {
    return _currentTime;
}

/**
 * @description init subviews
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)pSetupSubviews {
    
    // play button
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(20, 5, 40, 40)];
    [self.playButton setTitle:@"播" forState:UIControlStateNormal];
    [self.playButton setBackgroundColor:[UIColor greenColor]];
    [self.playButton addTarget:self action:@selector(playButtonActionCallBack:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    // progress container 
    self.progressContainerView = [[UIView alloc]initWithFrame:CGRectMake(70, 20, self.bounds.size.width - 70 - 70, 15)];
    self.progressContainerView.backgroundColor = [UIColor purpleColor];
    [self addSubview:self.progressContainerView];
    
    // loaded view
    self.loadedView = [[UIView alloc]initWithFrame:CGRectMake(self.progressContainerView.frame.origin.x, self.progressContainerView.frame.origin.y, 0, self.progressContainerView.frame.size.height)];
    self.loadedView.backgroundColor = [UIColor redColor];
    [self addSubview:self.loadedView];
    
    // played view
    self.playedView = [[UIView alloc]initWithFrame:CGRectMake(self.progressContainerView.frame.origin.x, self.progressContainerView.frame.origin.y, 0, self.progressContainerView.frame.size.height)];
    self.playedView.backgroundColor = [UIColor blueColor];
    [self addSubview:self.playedView];
    
    // drag idot
    self.idotImageView = [[UIImageView alloc]initWithFrame:CGRectMake(self.progressContainerView.frame.origin.x - 15, self.progressContainerView.frame.origin.y - 10, 30, 30)];
    self.idotImageView.layer.cornerRadius = 15.0;
    self.idotImageView.clipsToBounds = true;
    self.idotImageView.backgroundColor = [UIColor yellowColor];
    [self addSubview:self.idotImageView];
}

- (void)pSetupDragAction {
    
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
