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
@property (nonatomic, assign) BOOL isReady; //是否可以播放
@property (nonatomic, assign) BOOL isPlaying; //是否正在播放
@property (nonatomic, assign) BOOL isDraggedPaues; //是否由于拖动引起暂停
@property (nonatomic, strong) UIActivityIndicatorView *activityView; //加载圈
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, assign) CGRect originalFrame;
@property (nonatomic, strong) UIButton *coverButton;

@end

// play status:play
static NSString * const kPlayStatusPlay = @"kPlayStatus_Play";
// play status:pause
static NSString * const kPlayStatusPause = @"kPlayStatus_Pause";

// screen full
static NSString * const kScreenStatusFull = @"kScreenStatusFull";
// screen not full
static NSString * const kScreenStatusNotFull = @"kScreenStatusNotFull";

@implementation WWPlayer
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor blackColor];
        self.originalFrame = frame;
        [self pSetupPlayer];
        [self pSetupPlayerBar];
        [self pSetupTapAction];
        [self pSetupActivity];
        [self pSetupPlayerCoverButton];
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
    //http://vfx.mtime.cn/Video/2019/03/09/mp4/190309153658147087.mp4
    //http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4
    
    AVPlayerItem *playerItem = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"rtmp://202.69.69.180:443/webcast/bshdlive-pc"]];
    self.avPlayer = [[AVPlayer alloc]initWithPlayerItem:playerItem];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.avPlayer];
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    self.playerLayer.frame = self.bounds;
    [self.layer addSublayer:self.playerLayer];
    
    // 监听播放状态
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓冲进度
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓冲是否为空
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    
    // 监听缓冲是否可以播放
    [self.avPlayer.currentItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
    selector:@selector(playerPlayDidEnd:)
        name:AVPlayerItemDidPlayToEndTimeNotification
      object:playerItem];
    
    // 当前播放时间监听
    __weak __typeof(self) weakSelf = self;
    [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:nil usingBlock:^(CMTime time) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSInteger currentTime = strongSelf.avPlayer.currentItem.currentTime.value / strongSelf.avPlayer.currentItem.currentTime.timescale;
        NSInteger durationTime = strongSelf.avPlayer.currentItem.duration.value / strongSelf.avPlayer.currentItem.duration.timescale;
        strongSelf.playerBar.currentTime = currentTime;
        strongSelf.playerBar.totalDuration = durationTime;
    }];
}

- (void)playerPlayDidEnd:(NSNotification *)notification {
    if (self.avPlayer) {
        [self.avPlayer seekToTime:CMTimeMake(0, 1)];
        [self.playerBar seekToBegin];
    }
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
        NSDictionary *info;
        switch (currentStatus) {
            case AVPlayerItemStatusReadyToPlay:
                self.isReady = true;
                NSLog(@"可以播放了");
                break;
            case AVPlayerItemStatusFailed:
                self.isReady = false;
                info = @{@"error":@"AVPlayerItemStatusFailed"};
                if (self.delegate && [self.delegate respondsToSelector:@selector(playerDidError:)]) {
                    [self.delegate playerDidError:info];
                }
                break;
            case AVPlayerItemStatusUnknown:
                self.isReady = false;
                info = @{@"error":@"AVPlayerItemStatusUnknown"};
                if (self.delegate && [self.delegate respondsToSelector:@selector(playerDidError:)]) {
                    [self.delegate playerDidError:info];
                }
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
            //float startSeconds = CMTimeGetSeconds(timeRange.start);
            float loadedDurationSeconds = CMTimeGetSeconds(timeRange.duration);
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
* @description setup player bar
* @author waitwalker
* @date 2020.1.20
* @parameter
*/
- (void)pSetupPlayerCoverButton {
    self.coverButton = [[UIButton alloc]initWithFrame:CGRectMake((self.bounds.size.width - 70) / 2, (self.bounds.size.height - 70) / 2, 70, 70)];
    [self.coverButton setImage:[self imageName:@"player_play_cover@2x"] forState:UIControlStateNormal];
    [self.coverButton addTarget:self action:@selector(coverButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.coverButton];
}

- (void)coverButtonAction:(UIButton *)button {
    [self.playerBar play];
}

- (UIImage *)imageName:(NSString *)name{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"icons" ofType:@"bundle"]];
    NSString *path = [bundle pathForResource:name ofType:@"png"];
    return [[UIImage imageWithContentsOfFile:path] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
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
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(20.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
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
    if (@available(iOS 13.0, *)) {
        self.activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        // Fallback on earlier versions
        self.activityView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    self.activityView.center = CGPointMake(self.bounds.size.width / 2.0, self.bounds.size.height / 2.0);
    [self addSubview:self.activityView];
}

// MARK: public methods
- (void)play {
    if (self && self.avPlayer) {
        [self.avPlayer play];
        self.isPlaying = true;
        self.coverButton.hidden = true;
    } else {
        self.isPlaying = false;
        NSLog(@"播放遇到问题");
    }
}

- (void)pause {
    if (self && self.avPlayer) {
        [self.avPlayer pause];
        self.coverButton.hidden = false;
    } else {
        NSLog(@"暂停遇到问题");
    }
    self.isPlaying = false;
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
            [self play];
        } else {
            [self pause];
        }
    } else {
        NSLog(@"播放按钮回调数据有问题");
    }
}

/**
* @description drag begin call back
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)dDragBeganProgress:(NSDictionary *)info {
    if (self.isPlaying && self.avPlayer) {
        [self.avPlayer pause];
        self.isDraggedPaues = true;
    } else {
        self.isDraggedPaues = false;
    }
}

/**
* @description drag end call back
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)dDragEndedProgress:(NSDictionary *)info {
    CGFloat currentTime = [info[@"currentTime"] floatValue];
    if (self.avPlayer) {
        [self.avPlayer seekToTime:CMTimeMake((NSInteger)currentTime, 1)];
        if (self.isDraggedPaues) {
            [self.avPlayer play];
            self.isDraggedPaues = false;
        }
    }
}

/**
* @description full button call back
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)dTappedFullButton:(NSDictionary *)info {
    NSString *screenStatus = info[@"screenStatus"];
    // 全屏
    if ([screenStatus isEqualToString:kScreenStatusFull]) {
        [self pEnterFullAction];
    } else {
        [self pExitFullAction];
    }
}

/**
* @description enter full screen
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)pEnterFullAction {
    //添加到Window上
    UIWindow *keyWindow = [UIApplication sharedApplication].keyWindow;
    [keyWindow addSubview:self];

    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(M_PI / 2);

    }];
    self.frame = CGRectMake(0, 0, MIN([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height), MAX([UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height));
    self.playerLayer.frame = self.bounds;
    self.playerBar.frame = CGRectMake(0, self.bounds.size.height - 50, self.bounds.size.width, 50);
    self.coverButton.frame = CGRectMake((self.bounds.size.width - 70) / 2, (self.bounds.size.height - 70) / 2, 70, 70);
    [self.playerBar enterFullScreen];
}

/**
* @description exit full screen
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)pExitFullAction {
    [UIView animateWithDuration:0.25 animations:^{
        self.transform = CGAffineTransformMakeRotation(0);
    }];
    self.frame = self.originalFrame;
    self.playerLayer.frame = self.bounds;
    self.playerBar.frame = CGRectMake(0, self.bounds.size.height - 50, self.bounds.size.width, 50);
    self.coverButton.frame = CGRectMake((self.bounds.size.width - 70) / 2, (self.bounds.size.height - 70) / 2, 70, 70);
    [self.playerBar exitFullScreen];
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

    if (self.playerBar) {
        [self.playerBar removeFromSuperview];
        self.playerBar = nil;
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
@property (nonatomic, strong) UIButton *fullButton;
@property (nonatomic, strong) UIView *progressContainerView;
@property (nonatomic, strong) UIView *bufferedView;
@property (nonatomic, strong) UIView *playedView;
@property (nonatomic, strong) UIImageView *idotImageView;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *totalTimeLabel;
@property (nonatomic, assign) BOOL isSetted;
@end

@implementation WWPlayerBar
// MARK: 成员变量声明
@synthesize totalDuration = _totalDuration;
@synthesize currentTime = _currentTime;
@synthesize totalLoadedTime = _totalLoadedTime;

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [[UIColor colorWithRed:51.0/255 green:153.0/255 blue:255.0/255 alpha:1.0]colorWithAlphaComponent:0.25];
        [self pSetupSubviews];
        [self pSetupDragAction];
    }
    return self;
}

// MARK: setter
- (void)setTotalDuration:(NSInteger)totalDuration {
    _totalDuration = totalDuration;
    NSString *totalStr = [self timeFormat:totalDuration];
    self.totalTimeLabel.text = [NSString stringWithFormat:@"%@",totalStr];
}

- (NSInteger)totalDuration {
    return _totalDuration;
}

- (void)setTotalLoadedTime:(float)totalLoadedTime {
    _totalLoadedTime = totalLoadedTime;
    if (_totalDuration > 0) {
        self.bufferedView.frame = CGRectMake(0, 0, (totalLoadedTime / self.totalDuration) * self.progressContainerView.bounds.size.width, self.progressContainerView.bounds.size.height);
    }
}

- (float)totalLoadedTime {
    return _totalLoadedTime;
}

- (void)setCurrentTime:(NSInteger)currentTime {
    _currentTime = currentTime;
    NSString *currentStr = [self timeFormat:currentTime];
    self.currentTimeLabel.text = [NSString stringWithFormat:@"%@",currentStr];
    if (_totalDuration > 0) {
        CGFloat progressScale = ((CGFloat)currentTime / (CGFloat)self.totalDuration);
        CGFloat width = progressScale * (self.progressContainerView.frame.size.width - 20);
        self.idotImageView.frameX = width;
        self.playedView.frameWidth = self.idotImageView.frameX + 5;
    }
}

- (NSInteger)currentTime {
    return _currentTime;
}

- (void)seekToBegin {
    if (self.playButton) {
        [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)play {
    [self.playButton sendActionsForControlEvents:UIControlEventTouchUpInside];
}

/**
 * @description init subviews
 * @author waitwalker
 * @date 2020.1.20
 * @parameter 
 */
- (void)pSetupSubviews {
    
    // play button
    self.playButton = [[UIButton alloc]initWithFrame:CGRectMake(10, 5, 40, 40)];
    [self.playButton setImage:[self imageName:@"player_play@2x"] forState:UIControlStateNormal];
    [self.playButton addTarget:self action:@selector(playButtonActionCallBack:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.playButton];
    
    // progress container 
    self.progressContainerView = [[UIView alloc]initWithFrame:CGRectMake(60, 23.5, self.bounds.size.width - 60 - 100, 3)];
    self.progressContainerView.layer.cornerRadius = 1.5;
    self.progressContainerView.backgroundColor = [[UIColor grayColor]colorWithAlphaComponent:0.3];
    [self addSubview:self.progressContainerView];
    
    // buffer view
    self.bufferedView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, self.progressContainerView.frame.size.height)];
    self.bufferedView.layer.cornerRadius = 2.5;
    self.bufferedView.clipsToBounds = true;
    self.bufferedView.backgroundColor = [[UIColor grayColor]colorWithAlphaComponent:0.9];
    [self.progressContainerView addSubview:self.bufferedView];
    
    // played view
    self.playedView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 0, self.progressContainerView.frame.size.height)];
    self.playedView.layer.cornerRadius = 2.5;
    self.playedView.clipsToBounds = true;
    self.playedView.backgroundColor = [[UIColor colorWithRed:51.0/255 green:153.0/255 blue:255.0/255 alpha:1.0]colorWithAlphaComponent:0.9];
    [self.progressContainerView addSubview:self.playedView];
    
    // drag idot
    self.idotImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, -12.5, 25, 25)];
    self.idotImageView.layer.cornerRadius = 12.5;
    self.idotImageView.clipsToBounds = true;
    self.idotImageView.userInteractionEnabled = true;
    self.idotImageView.backgroundColor = [UIColor whiteColor];
    [self.progressContainerView addSubview:self.idotImageView];

    self.currentTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.progressContainerView.frame) + 10, 8, 50, 20)];
    self.currentTimeLabel.textColor = [UIColor whiteColor];
    self.currentTimeLabel.textAlignment= NSTextAlignmentLeft;
    self.currentTimeLabel.font = [UIFont systemFontOfSize:10];
    self.currentTimeLabel.text = @"00:00";
    [self addSubview:self.currentTimeLabel];

    self.totalTimeLabel = [[UILabel alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.progressContainerView.frame) + 10, 15, 50, 30)];
    self.totalTimeLabel.textColor = [UIColor whiteColor];
    self.totalTimeLabel.textAlignment= NSTextAlignmentLeft;
    self.totalTimeLabel.font = [UIFont systemFontOfSize:10];
    [self addSubview:self.totalTimeLabel];

    // full button
    self.fullButton = [[UIButton alloc]initWithFrame:CGRectMake(CGRectGetMaxX(self.totalTimeLabel.frame), 10, 30, 30)];
    [self.fullButton setImage:[self imageName:@"player_enter_fullscreen@2x"] forState:UIControlStateNormal];
    [self.fullButton addTarget:self action:@selector(fullButtonActionCallBack:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.fullButton];
}

/**
* @description enter full screen
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)enterFullScreen {
    self.playButton.frame =  CGRectMake(50, 5, 40, 40);
    self.progressContainerView.frame = CGRectMake(100, 23.5, self.bounds.size.width - 100 - 140, 3);
    [self pLayoutSubviews];
}

/**
* @description exit full screen
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)exitFullScreen {
    self.playButton.frame =  CGRectMake(10, 5, 40, 40);
    self.progressContainerView.frame = CGRectMake(60, 23.5, self.bounds.size.width - 60 - 100, 3);
    [self pLayoutSubviews];
}

/**
* @description relayout subviews
* @author waitwalker
* @date 2020.1.27
* @parameter
*/
- (void)pLayoutSubviews {
    [self setTotalDuration:self.totalDuration];
    [self setTotalLoadedTime:self.totalLoadedTime];
    [self setCurrentTime:self.currentTime];
    self.currentTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.progressContainerView.frame) + 10, 8, 50, 20);
    self.totalTimeLabel.frame = CGRectMake(CGRectGetMaxX(self.progressContainerView.frame) + 10, 15, 50, 30);
    self.fullButton.frame = CGRectMake(CGRectGetMaxX(self.totalTimeLabel.frame), 10, 30, 30);
}

/**
* @description init drag
* @author waitwalker
* @date 2020.1.20
* @parameter 
*/
- (void)pSetupDragAction {
    UIPanGestureRecognizer *panGes = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panActionCallBack:)];
    panGes.maximumNumberOfTouches = 1;
    panGes.minimumNumberOfTouches = 1;
    [self.idotImageView addGestureRecognizer:panGes];
}

/**
* @description  drag action call back
* @author waitwalker
* @date 2020.1.25
* @parameter
*/
- (void)panActionCallBack:(UIPanGestureRecognizer *)panGes {
    //获取偏移量
    CGFloat moveX = [panGes translationInView:self].x;
    
    //重置偏移量，避免下次获取到的是原基础的增量
    [panGes setTranslation:CGPointMake(0, 0) inView:self];
    
    CGFloat centerX = _idotImageView.centerX + moveX;
    if (centerX < 10) centerX = 10;
    if (centerX > self.bounds.size.width - 10) centerX = self.progressContainerView.bounds.size.width - 10;
    _idotImageView.centerX = centerX;
    if (_idotImageView.centerX < 10) {
        _idotImageView.centerX = 10;
    } else if (_idotImageView.centerX > self.progressContainerView.bounds.size.width - 10) {
        _idotImageView.centerX = self.progressContainerView.bounds.size.width - 10;
    }
    self.playedView.frameWidth = self.idotImageView.frameX + 5;
    CGFloat X = _idotImageView.centerX - 10;
    if (X >= self.progressContainerView.bounds.size.width - 10) {
        X += 10;
    }
    CGFloat progressScale = X / self.progressContainerView.frame.size.width;
    CGFloat currentTime = progressScale * self.totalDuration;
    if (panGes.state == UIGestureRecognizerStateBegan) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(dDragBeganProgress:)]) {
            [self.delegate dDragBeganProgress:@{@"dragStatus":@"began"}];
        }
    } else if (panGes.state == UIGestureRecognizerStateEnded) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(dDragEndedProgress:)]) {
            [self.delegate dDragEndedProgress:@{@"currentTime":@(currentTime),
                                                @"dragStatus":@"ended"}];
        }
    }
}

/**
* @description play button tap call back
* @author waitwalker
* @date 2020.1.25
* @parameter
*/
- (void)playButtonActionCallBack:(UIButton *)button {
    self.playButton.selected = !self.playButton.selected;
    if (self.playButton.selected) {
        [self.playButton setImage:[self imageName:@"player_pause@2x"] forState:UIControlStateNormal];
    } else {
        [self.playButton setImage:[self imageName:@"player_play@2x"] forState:UIControlStateNormal];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(dTappedPlayButton:)]) {
        NSString *playStatus = self.playButton.selected ? kPlayStatusPlay : kPlayStatusPause;
        [self.delegate dTappedPlayButton:@{@"playStatus":playStatus}];
    }
}

/**
* @description full button tap call back
* @author waitwalker
* @date 2020.1.25
* @parameter
*/
- (void)fullButtonActionCallBack:(UIButton *)button {
    self.fullButton.selected = !self.fullButton.selected;
    if (self.fullButton.selected) {
        [button setImage:[self imageName:@"player_exit_fullscreen@2x"] forState:UIControlStateNormal];
    } else {
        [button setImage:[self imageName:@"player_enter_fullscreen@2x"] forState:UIControlStateNormal];
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(dTappedFullButton:)]) {
        NSString *screenStatus = self.fullButton.selected ? kScreenStatusFull : kScreenStatusNotFull;
        [self.delegate dTappedFullButton:@{@"screenStatus":screenStatus}];
    }
}

/**
* @description play time format
* @author waitwalker
* @date 2020.1.20
* @parameter
*/
-(NSString *)timeFormat:(NSInteger)totalTime{
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(totalTime % 3600) / 60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%02ld",totalTime % 60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    return format_time;
}

- (UIImage *)imageName:(NSString *)name{
    NSBundle *bundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:@"icons" ofType:@"bundle"]];
    NSString *path = [bundle pathForResource:name ofType:@"png"];
    return [[UIImage imageWithContentsOfFile:path] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}

@end

// MARK: UIView Category
@implementation UIView (Category)
- (CGFloat)frameX {
    return self.frame.origin.x;
}

- (void)setFrameX:(CGFloat)newX {
    self.frame = CGRectMake(newX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (CGFloat)frameY {
    return self.frame.origin.y;
}

- (void)setFrameY:(CGFloat)newY {
    self.frame = CGRectMake(self.frame.origin.x, newY, self.frame.size.width, self.frame.size.height);
}

- (CGFloat)frameWidth {
    return self.frame.size.width;
}

- (void)setFrameWidth:(CGFloat)newWidth {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, self.frame.size.height);
}

- (CGFloat)frameHeight {
    return self.frame.size.height;
}

- (void)setFrameHeight:(CGFloat)newHeight {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, newHeight);
}

- (CGPoint)frameOrigin {
    return self.frame.origin;
}

- (void)setFrameOrigin:(CGPoint)newOrigin {
    self.frame = CGRectMake(newOrigin.x, newOrigin.y, self.frame.size.width, self.frame.size.height);
}

- (CGSize)frameSize {
    return self.frame.size;
}

- (void)setFrameSize:(CGSize)newSize {
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newSize.width, newSize.height);
}

- (CGFloat)boundsX {
    return self.bounds.origin.x;
}

- (void)setBoundsX:(CGFloat)newX {
    self.bounds = CGRectMake(newX, self.bounds.origin.y, self.bounds.size.width, self.bounds.size.height);
}

- (CGFloat)boundsY {
    return self.bounds.origin.y;
}

- (void)setBoundsY:(CGFloat)newY {
    self.bounds = CGRectMake(self.bounds.origin.x, newY, self.bounds.size.width, self.bounds.size.height);
}

- (CGFloat)boundsWidth {
    return self.bounds.size.width;
}

- (void)setBoundsWidth:(CGFloat)newWidth {
    self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, newWidth, self.bounds.size.height);
}

- (CGFloat)boundsHeight {
    return self.bounds.size.height;
}

- (void)setBoundsHeight:(CGFloat)newHeight {
    self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, newHeight);
}

- (CGFloat)centerX {
    return self.center.x;
}

- (void)setCenterX:(CGFloat)newX {
    self.center = CGPointMake(newX, self.center.y);
}

- (CGFloat)centerY {
    return self.center.y;
}

- (void)setCenterY:(CGFloat)newY{
    self.center = CGPointMake(self.center.x, newY);
}
@end
